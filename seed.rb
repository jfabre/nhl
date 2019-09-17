# frozen_string_literal: true

# Seeds random data for the schema
# rubocop:disable ClassLength
class Seed
  # So goalies don't have the same amount of goals
  RANDOM_PLAYERS_SQL = <<~SQL
    SELECT p.*
    FROM players p
    INNER JOIN teams t
      ON p.team_id = t.id
    INNER JOIN attendances a
      ON a.team_id = t.id
      AND a.player_id = p.id
    INNER JOIN positions pos
      ON a.position_id = pos.id
    INNER JOIN games g
      ON a.game_id = g.id
    WHERE pos.id != ? AND g.id = ? AND t.id = ?
  SQL

  POSITIONS = %i[
    center forward_right forward_left
    defense_left defense_right goalie
  ].map(&:to_s).freeze

  def initialize(db)
    @db = db
  end

  def create
    create_locations
    create_teams
    create_players
    create_positions

    200.times do |i|
      generate_game_and_goals i
    end
  end

  private

  def random_location
    (@location_ids ||= @db[:locations].all.map { |l| l[:id] }).sample
  end

  def random_players(game_id, team_id)
    @goalie_id ||= @db[:positions].where(name: 'goalie').first[:id]

    @db.fetch(RANDOM_PLAYERS_SQL, @goalie_id, game_id, team_id).to_a
  end

  def scorer(goal)
    random_players(goal[:game_id], goal[:scoring_team_id]).sample
  end

  def assist(goal)
    random_players(goal[:game_id], goal[:scoring_team_id]).select do |p|
      yield(p)
    end.sample
  end

  def random_game_time(start, index, total)
    from, to = [index, index + 1].map do |i|
      start + (1.hour / total) * i
    end
    Faker::Time.between(from: from, to: to)
  end

  def random_nights
    @random_nights ||= (1..200).map do
      Faker::Time.between_dates(from: 1.year.ago,
                                to: Date.today,
                                period: :night)
    end.sort
  end

  def team_ids
    @team_ids ||= @db[:teams].map { |t| t[:id] }
  end

  def create_attendances(game_id, team_id)
    players = @db[:players].where(team_id: team_id)
    attendances = @db[:positions].to_a.shuffle.zip(players)

    attendances.each do |pos, player|
      @db[:attendances].insert(position_id: pos[:id],
                               team_id: team_id,
                               game_id: game_id,
                               player_id: player[:id])
    end
  end

  def create_goal(goal)
    goal = goal.dup

    s  = scorer(goal)
    a1 = assist(goal) { |p| p != s }
    a2 = assist(goal) { |p| ![s, a1].include?(p) }

    goal[:player_id] = s[:id]
    goal[:assist1_id] = a1[:id]
    goal[:assist2_id] = a2[:id]

    @db[:scores].insert(goal)
  end

  def create_locations
    3.times do |i|
      @db[:locations].insert(name: "Gymnase #{i + i}")
    end
  end

  def create_teams
    4.times do
      @db[:teams].insert(color: Faker::Color.color_name)
    end
  end

  def create_players
    team_ids.each do |team_id|
      6.times do
        @db[:players].insert(team_id: team_id, name: Faker::Name.name)
      end
    end
  end

  def create_positions
    POSITIONS.each do |p|
      @db[:positions].insert(name: p)
    end
  end

  def create_game(time, home_id, visitor_id)
    @db[:games].insert(location_id: random_location,
                       start: time,
                       home_team_id: home_id,
                       visitor_team_id: visitor_id)
  end

  def generate_home_id
    team_ids.sample
  end

  def generate_visitor_id(home_id)
    team_ids.reject { |t| t == home_id }.sample
  end

  GOALIE_SQL = "
    SELECT p.id
    FROM players p
    INNER JOIN attendances a
      ON p.id = a.player_id
    INNER JOIN positions pos
      ON a.position_id = pos.id
    INNER JOIN teams t
      ON t.id = a.team_id
    WHERE a.game_id = ?
    AND t.id = ?
    AND pos.name = 'goalie'
  "
  def find_goalie(game_id, team_id)
    @db.fetch(GOALIE_SQL, game_id, team_id).first[:id]
  end

  def generate_game_and_goals(index)
    home_id = generate_home_id
    visitor_id = generate_visitor_id(home_id)
    game_id = create_game(random_nights[index], home_id, visitor_id)
    team_ids = [home_id, visitor_id]

    team_ids.each do |team_id|
      create_attendances(game_id, team_id)
    end
    generate_goals(team_ids, game_id, index, rand(0..6))
  end

  def generate_goals(team_ids, game_id, index, goal_count)
    team_ids.permutation.each do |scoring, scored|
      goals = goal_count.times.map do |c|
        {
          game_id: game_id, scoring_team_id: scoring, scored_team_id: scored,
          goalie_id: find_goalie(game_id, scored),
          at: random_game_time(random_nights[index], c, goal_count)
        }
      end
      goals.each { |g| create_goal(g) }
    end
  end
end
# rubocop:enable ClassLength
