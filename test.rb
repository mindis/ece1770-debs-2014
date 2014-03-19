#!/usr/bin/env ruby 

# --debug -S rdebug

# Very preliminary and basic test script that reads input values from a CSV 
# and runs them through the plug and house bolt calculations.

require 'cql'
require 'csv'
require 'lib/debs/cassandra_helpers.rb'
require 'lib/debs/plug_helpers.rb'
require 'lib/debs/debs_helpers.rb'

# require 'ruby-debug'

include DebsHelpers
include CassandraHelpers
include PlugHelpers

def process_tuple_for_plug(tuple)
  # input_fields :timestamp, :value, :property, :plug_id, :household_id, :house_id
  @tuple = tuple
  update_current_plug_load
  predicted = predict_plug_load
  {
    :timstamp => timestamp, 
    :house_id => house_id, 
    :household_id => household_id, 
    :plug_id => plug_id, 
    :predicted_load => predicted
  }
end

def process_tuple_for_house(tuple)
  @tuple = tuple
  update_current_house_load
  predicted = predict_house_load
  {
    :timestamp => timestamp, 
    :house_id => house_id, 
    :predicted_load => predicted
  }
end

def process_file(filename)
  last_timestamp = -1
  CSV.foreach(filename) do |row|
    tuple = {
      :id           => row[0].to_i,
      :timestamp    => row[1].to_i,
      :value        => row[2].to_f,
      :property     => row[3].to_i,
      :plug_id      => row[4].to_i,
      :household_id => row[5].to_i,
      :house_id     => row[6].to_i
    }
    plug_bolt_output = process_tuple_for_plug(tuple)
    last_timestamp = tuple[:timestamp]

    house_bolt_output = process_tuple_for_house(tuple)
  end
  last_timestamp
end

setup_cassandra
set_base_timestamp(1379879533)

last_timestamp = process_file("test/test1.csv")
s_i = slice_index(last_timestamp)
puts "LAST TIMESTAMP #{last_timestamp} => SLICE #{s_i}"

(0..s_i+2).each do |i|
  # puts "PLUG 1: #{get_plug_avgLoad(i, 1, 1, 1)}"
  # puts "PLUG 2: #{get_plug_avgLoad(i, 1, 2, 1)}"
  puts "SLICE INDEX: #{i}, HOUSE LOAD: #{get_house_avgLoad(i, 1)}"
end

