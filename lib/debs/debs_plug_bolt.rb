require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'

class DebsPlugBolt < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers
  include PlugHelpers

  output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id, :start_time

  on_receive :emit => true, :ack => true, :anchor => false do |tuple|
    @tuple = tuple
    update_current_plug_load
    [id, timestamp, value, property, plug_id, household_id, house_id, start_time]
  end
end
