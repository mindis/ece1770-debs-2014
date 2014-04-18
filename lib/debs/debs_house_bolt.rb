require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'

class DebsHouseBolt < RedStorm::DSL::Bolt

  include DebsHelpers

  DEBUG = false

  configure do
    debug DEBUG
  end

  output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id

  on_receive :emit => true, :ack => true, :anchor => false do |tuple| 
    @tuple = tuple
    [id, timestamp, value, property, plug_id, household_id, house_id]
  end

end
