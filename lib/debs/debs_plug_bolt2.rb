require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'

class DebsPlugBolt2 < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers
  include PlugHelpers

  output_fields :id, :timestamp, :house_id, :household_id, :plug_id, :predicted_load, :start_time

  on_receive :emit => true, :ack => true, :anchor => false do |tuple|
    @tuple = tuple
    predicted = predict_plug_load
    [id, timestamp, house_id, household_id, plug_id, predicted, start_time]
  end

end
