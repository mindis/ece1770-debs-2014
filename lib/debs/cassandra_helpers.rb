require 'cql'

module CassandraHelpers

  def store
    if @store == nil
      @store = cassandra_client
      @store.use('measurements')
    end
    @store
  end

  def cassandra_client
    Cql::Client.connect(hosts: ['127.0.0.1'])
  end

  def set_base_timestamp(ts)
    query = "INSERT INTO Globals (name, value) VALUES ('%s', '%s')" % ["base_timestamp", ts.to_s]
    store.execute(query)
  end

  def get_base_timestamp
    query = "SELECT value FROM Globals WHERE name = '%s'" % ["base_timestamp"]
    results = store.execute(query)
    value = results.first["value"]
    raise "No base_timestamp set!" if value.nil?
    value.to_i
  end

  # It's convenient to initialize this here.
  def setup_cassandra
    puts "<<< SETTING UP CASSANDRA >>>"

    client = cassandra_client

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

      begin
        client.execute("DROP TABLE IF EXISTS Globals")
      rescue Cql::QueryError => e
        # nop
      end

      # slice_index is a convenience. It could be determined by timestamp.
      table_definition = <<-TABLEDEF
        CREATE TABLE InstantaneousPlugLoads (
        plug_id BIGINT,
        house_id BIGINT,
        household_id BIGINT,
        timestamp BIGINT,
        slice_index INT,
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

      table_definition = <<-TABLEDEF
        CREATE TABLE Globals (
        name VARCHAR,
        value VARCHAR,
        PRIMARY KEY (name)
        )
      TABLEDEF
      client.execute(table_definition)
      # client.add(table_definition)

      index_definition = <<-INDEXDEF
        CREATE INDEX InstantaneousPlugLoadsSliceIndex ON
          InstantaneousPlugLoads
          (slice_index)
      INDEXDEF
      client.execute(index_definition)


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
