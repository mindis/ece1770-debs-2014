require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'

class DebsDummyClientBolt < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers
  include PlugHelpers

  output_fields :id, :timestamp, :start_time, :end_time

  on_init do
    @count = 0
    @max_id = -1
  end

  on_receive :emit => false, :ack => false, :anchor => false do |tuple|
    @tuple = tuple

    # Latency
    etime = Time.now.to_f
    delta = etime - start_time
    
    # We just use this to track throughput
    @count = @count + 1
    @max_id = [@max_id, id].max

    if @count % 1000 == 0
      puts "[CLIENT] COUNT_OUT: #{@count}, MAX_ID_OUT: #{@max_id}, CURRENT_ID: #{id}, DELTA: #{delta}"
      record_metric('count_out', @count)
      record_metric('max_id_out', @max_id)
      record_metric('current_id_out', id)
      record_metric('delta_out', delta)
    end
    ack(tuple)
    [id, timestamp, start_time, etime]
  end

end
