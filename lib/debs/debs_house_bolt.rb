require 'red_storm'

class DebsHouseBolt < RedStorm::DSL::Bolt

  include DebsHelpers

  DEBUG = false

  configure do
    debug DEBUG
  end

  output_fields :timestamp, :value, :property, :plug_id, :household_id, :house_id

  on_receive :emit => true, :ack => true, :anchor => true do |tuple| 
    @tuple = tuple
    [timestamp, value, property, plug_id, household_id, house_id]
  end

end