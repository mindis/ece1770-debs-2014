require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'

class DebsHouseCalcBolt2 < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers
  include PlugHelpers

  DEBUG = false

  configure do
    debug DEBUG
  end

  output_fields :id, :timestamp, :house_id, :predicted_house_load

  on_receive :emit => true, :ack => true, :anchor => false do |tuple|
    @tuple = tuple
    predicted = predict_house_load
    [id, timestamp, house_id, predicted]
  end

end
