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

  # input_fields :timestamp, :house_id, :household_id, :plug_id, :predicted_plug_load
  output_fields :timestamp, :house_id, :predicted_house_load

  # emit is false because we're not always emitting
  on_receive :emit => false, :ack => false, :anchor => false do |tuple|
    @tuple = tuple

    predicted = predict_house_load
    datum = [timestamp, house_id, predicted]
    anchored_emit(tuple, *datum)

    ack(tuple)
  end

end
