# frozen_string_literal: true

# Statistics on the players
class Stats
  attr_reader :db

  def initialize(db)
    @db = db
  end

  def top_5_scorers
    q = "
      SELECT p.name, count(s.id) as goals
      FROM players p
      INNER JOIN scores s
        ON s.player_id = p.id
      GROUP BY p.name
      ORDER BY goals DESC
      LIMIT 5
    "
    db.fetch(q)
  end

  def top_5_pointers
    q = "
      SELECT p.name, count(s.id) as points
      FROM players p
      INNER JOIN scores s
        ON s.player_id = p.id OR s.assist1_id = p.id OR s.assist2_id = p.id
      GROUP BY p.name
      ORDER BY points DESC
      LIMIT 5
    "
    db.fetch(q)
  end

  def top_5_goalies
    q = "
      SELECT p.name, count(s.id) as goals
      FROM players p
      INNER join attendances a
        ON a.player_id = p.id
      INNER JOIN games g
        ON g.id = a.game_id
      INNER JOIN scores s
        ON s.game_id = g.id
        AND s.goalie_id = p.id
      GROUP BY p.name
      ORDER BY count(s.id)
    "
    db.fetch(q).take(5)
  end

  def most_goals_on_goalies
    q = "
      SELECT p.name as goalie, p2.name as scorer, count(s.id) as goals
      FROM scores s
      INNER JOIN players p
        ON s.goalie_id = p.id
      INNER JOIN players p2
        ON s.player_id = p2.id
      GROUP BY goalie, scorer
      ORDER BY goals DESC
    "

    db.fetch(q).take(5)
  end
end
