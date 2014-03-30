require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'

class DebsPlugBolt2 < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers
  include PlugHelpers

  DEBUG = false

  configure do
    debug DEBUG
  end

  # input_fields :timestamp, :value, :property, :plug_id, :household_id, :house_id
  output_fields :timestamp, :house_id, :household_id, :plug_id, :predicted_load

  on_init do
    # nop
  end

  on_receive :emit => false, :ack => false, :anchor => false do |tuple|
    @tuple = tuple
    predicted = predict_plug_load
    datum = [timestamp, house_id, household_id, plug_id, predicted]
    anchored_emit(tuple, *datum)
    ack(tuple)
  end

end
