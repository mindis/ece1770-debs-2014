require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'

class DebsDummyClientBolt < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers
  include PlugHelpers

  DEBUG = false

  configure do
    debug DEBUG
  end

  output_fields :id, :timestamp

  on_init do
    @count = 0
    @max_id = -1
  end

  on_receive :emit => false, :ack => false, :anchor => false do |tuple|
    @tuple = tuple
    
    # We just use this to track throughput
    @count = @count + 1
    @max_id = [@max_id, id].max
    if @count % 1000 == 0
      puts "COUNT_OUT: #{@count}, MAX_ID_OUT: #{@max_id}, CURRENT_ID: #{id}"
      record_metric('count_out', @count)
      record_metric('max_id_out', @max_id)
    end
    ack(tuple)
    tuple
  end

end
