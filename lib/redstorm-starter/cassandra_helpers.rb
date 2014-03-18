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
