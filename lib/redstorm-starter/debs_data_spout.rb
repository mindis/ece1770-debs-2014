require 'red_storm'
require 'zlib'

# https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation

class DebsDataSpout < RedStorm::DSL::Spout

  DEBUG = false

  output_fields :timestamp, :value, :property, :plug_id, :household_id, :house_id

  configure do
    debug DEBUG
    # reliable true
  end

  on_send :emit => false do
    if @data.size > 0
      data = @data.shift #if @data.size > 0
      id = data[0]
      data = [data[1].to_i, data[2].to_f, data[3].to_i, data[4].to_i, data[5].to_i, data[6].to_i]
      puts "ID #{id}: #{data}" if DEBUG
      reliable_emit(data[0], *data)
    end
  end

  on_init do
    setup_store

    filepath = "/Users/dfcarney/src/ece1770/project/sorted.csv.gz"
    fd = File::open(filepath, "r")
    gz = Zlib::GzipReader.new(fd)

    # id, timestamp, value, property, plug_id, household_id, house_id
    @data = []
    while(gz.lineno < 100000) 
      id, timestamp, value, property, plug_id, household_id, house_id = gz.readline.strip.split(",")
      @data << [id.to_i, timestamp.to_i, value.to_f, property.to_i, plug_id.to_i, household_id.to_i, house_id.to_i]
    end
    true
  end

  on_close do
    puts "CLOSING #{self.class.to_s}"
    # ...
  end

  on_ack do |msg_id|
    # puts "ACK #{msg_id}"
    # ...
  end

  on_fail do |msg_id|
    puts "FAIL #{msg_id}"
    # ...
  end

  on_activate do
    puts "ACTIVATE"
    # ...
  end

  on_deactivate do
    puts "DEACTIVATE"
    # ...
  end

  # It's convenient to initialize this here.
  def setup_store
    client = Cql::Client.connect(hosts: ['127.0.0.1'])

    # Don't drop and recreate the keyspace as that might disrupt (debug) clients
    # client.execute('DROP KEYSPACE IF EXISTS measurements')
    begin
      client.use('measurements')
    rescue Cql::QueryError => e
      keyspace_definition = <<-KSDEF
        CREATE KEYSPACE measurements
        WITH replication = {
          'class': 'SimpleStrategy',
          'replication_factor': 1
        }
      KSDEF
      client.execute(keyspace_definition)
      client.use('measurements')
    rescue => e
      raise e
    ensure

      begin
        client.execute("DROP TABLE IF EXISTS InstantaneousPlugLoads")
      rescue Cql::QueryError => e
        # nop
      end

      begin
        client.execute("DROP TABLE IF EXISTS AveragePlugLoads")
      rescue Cql::QueryError => e
        # nop
      end

      table_definition = <<-TABLEDEF
        CREATE TABLE InstantaneousPlugLoads (
        plug_id BIGINT,
        house_id BIGINT,
        household_id BIGINT,
        timestamp BIGINT,
        load DOUBLE,
        PRIMARY KEY (house_id, household_id, plug_id, timestamp)
        )
      TABLEDEF
      client.execute(table_definition)
      # client.add(table_definition)

      table_definition = <<-TABLEDEF
        CREATE TABLE AveragePlugLoads (
        plug_id BIGINT,
        house_id BIGINT,
        household_id BIGINT,
        slice_index INT,
        load DOUBLE,
        predicted BOOLEAN,
        PRIMARY KEY (house_id, household_id, plug_id, slice_index)
        )
      TABLEDEF
      client.execute(table_definition)
      # client.add(table_definition)

      index_definition = <<-INDEXDEF
        CREATE INDEX AveragePlugLoadsPredictedIndex ON
          AveragePlugLoads
          (predicted)
      INDEXDEF
      client.execute(index_definition)
    end
    client
  end

end
