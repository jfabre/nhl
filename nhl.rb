# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'sequel'
  gem 'activesupport', require: 'active_support/all'
  gem 'sqlite3'
  gem 'faker'
  gem 'awesome_print'
end

require './schema.rb'
require './seed.rb'
require './stats.rb'

db = Sequel.sqlite
Schema.new(db).create
Seed.new(db).create

# Stats
# Top 5 Pointers
# Top 5 Goalies
#

stats = Stats.new(db)
puts ''
puts 'Top 5 Scorers'
puts ''

stats.top_5_scorers.each do |s|
  puts "#{s[:goals]} - #{s[:name]}"
end
puts ''
puts 'Top 5 Pointers'
puts ''
stats.top_5_pointers.each do |s|
  puts "#{s[:points]} - #{s[:name]}"
end

puts ''
puts 'Goalies that allowed the least goals'
puts ''
stats.top_5_goalies.each do |s|
  puts "#{s[:goals]} - #{s[:name]}"
end

puts ''
puts 'Most goals on Goalies'
puts ''
stats.most_goals_on_goalies.each do |s|
  puts "#{s[:goals]} - #{s[:scorer]} vs #{s[:goalie]}"
end
puts ''
