#!/usr/bin/env ruby

require 'cql'
require 'lib/debs/cassandra_helpers.rb'

include CassandraHelpers

query = "SELECT * from InstantaneousPlugLoads" # ORDER BY house_id, household_id, plug_id, timestamp" 
puts "#{query}"
puts store.execute(query).map{|row| row}

query = "SELECT * from AveragePlugLoads"
puts "\n#{query}"
puts store.execute(query).map{|row| row}

query = "SELECT * from AverageHouseLoads"
puts "\n#{query}"
puts store.execute(query).map{|row| row}


