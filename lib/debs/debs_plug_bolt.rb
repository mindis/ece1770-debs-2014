require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'

class DebsPlugBolt < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers
  include PlugHelpers

  DEBUG = false

  configure do
    debug DEBUG
  end

  # input_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
  output_fields :timestamp, :value, :property, :plug_id, :household_id, :house_id

  on_init do
    # nop
  end

  # emit is false because we're not always emitting
  on_receive :emit => false, :ack => false, :anchor => false do |tuple|
    @tuple = tuple
    if tuple_contains_load_value?
      update_current_plug_load
      datum = [timestamp, value, property, plug_id, household_id, house_id]
      anchored_emit(tuple, *datum)
    end
    ack(tuple)
  end

end
