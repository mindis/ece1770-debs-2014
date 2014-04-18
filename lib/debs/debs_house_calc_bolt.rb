require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'

class DebsHouseCalcBolt < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers
  include PlugHelpers

  DEBUG = false

  configure do
    debug DEBUG
  end

  output_fields :id, :timestamp, :house_id, :household_id, :plug_id, :predicted_plug_load

  on_receive :emit => true, :ack => true, :anchor => false do |tuple|
    @tuple = tuple
    # if tuple_contains_load_value? # True by virtue of the topology
    update_current_house_load
    [id, timestamp, house_id, household_id, plug_id, predicted_plug_load]
  end

end
