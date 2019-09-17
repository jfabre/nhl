# frozen_string_literal: true

# Creates the schema
class Schema
  def initialize(db)
    @db = db
  end

  def create_locations
    @db.create_table :locations do
      primary_key :id
      String :name
    end
  end

  def create_teams
    @db.create_table :teams do
      primary_key :id
      String :color
    end
  end

  def create_players
    @db.create_table :players do
      primary_key :id
      String :name
      Integer :team_id
    end
  end

  def create_games
    @db.create_table :games do
      primary_key :id
      Integer :location_id
      DateTime :start
      Integer :home_team_id
      Integer :visitor_team_id
    end
  end

  def create_positions
    @db.create_table :positions do
      primary_key :id
      String :name
    end
  end

  def create_attendances
    @db.create_table :attendances do
      primary_key :id
      Integer :position_id
      Integer :team_id
      Integer :game_id
      Integer :player_id
    end
  end

  def create_scores
    @db.create_table :scores do
      primary_key :id
      Integer :game_id
      Integer :player_id
      Integer :assist1_id
      Integer :assist2_id
      Integer :goalie_id
      Integer :scoring_team_id
      Integer :scored_team_id
      DateTime :at
    end
  end

  def create
    create_locations
    create_teams
    create_players
    create_games
    create_positions
    create_attendances
    create_scores
  end
end
