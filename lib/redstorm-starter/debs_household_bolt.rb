require 'red_storm'

class DebsHouseholdBolt < RedStorm::DSL::Bolt

  include DebsHelpers

  output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id

  on_receive :emit => true, :ack => true, :anchor => true do |tuple| 
    @tuple = tuple
    [id, timestamp, value, property, plug_id, household_id, house_id]
  end
  
end
