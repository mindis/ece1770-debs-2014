require 'red_storm'

class DebsHouseCalcBolt < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers

  DEBUG = false

  configure do
    debug DEBUG
  end

  # input_fields :id, :timestamp, :house_id, :household_id, :plug_id, :predicted_load
  output_fields :timestamp, :house_id, :predicted_load

  # on_init do
  #   @instantaneous_load = {} # :house_id, :household_id, :plug_id => :timestamp => :value
  #   @average_load = {} # :house_id, :household_id, :plug_id, :slice_index => :value
  #   @slice_duration_in_seconds = 60
  # end

  # emit is false because we're not always emitting
  on_receive :emit => false, :ack => false, :anchor => false do |tuple|
    @tuple = tuple
    # TODO
    unanchored_emit(*[1, 2, 3])
    ack(tuple)
  end

end
