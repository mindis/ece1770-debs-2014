require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'

# https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation

class DebsDataBolt < RedStorm::DSL::Bolt

  include Java
  include DebsHelpers

  DEBUG = false

  output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id

  configure do
    debug DEBUG
  end

  on_receive :emit => false, :ack => false, :anchor => false do |tuple| 
    values = tuple[0].to_s.split(",")
    @tuple = {
      :id           => values[0].to_i, 
      :timestamp    => values[1].to_i, 
      :value        => values[2].to_f, 
      :property     => values[3].to_i, 
      :plug_id      => values[4].to_i, 
      :household_id => values[5].to_i, 
      :house_id     => values[6].to_i
    }
    if tuple_contains_load_value?
      datum = [id, timestamp, value, property, plug_id, household_id, house_id]
      anchored_emit(tuple, *datum)
    end
    ack(tuple)
  end
end
