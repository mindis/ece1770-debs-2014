require 'red_storm'

class DebsPlugBolt < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers
  include PlugHelpers

  DEBUG = false

  configure do
    debug DEBUG
  end

  # input_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
  output_fields :timestamp, :house_id, :household_id, :plug_id, :predicted_load

  on_init do
    # nop
  end

  # emit is false because we're not always emitting
  on_receive :emit => false, :ack => false, :anchor => false do |tuple|
    @tuple = tuple
    if tuple_contains_load_value?
      update_current_plug_load
      predicted = predict_plug_load
      datum = [timestamp, house_id, household_id, plug_id, predicted]
      anchored_emit(tuple, *datum)
    end
    ack(tuple)
  end

end
