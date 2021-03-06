require 'cql'

module CassandraHelpers

  CASSANDRA_HOST="54.86.69.69"
  #CASSANDRA_HOST="192.168.50.7"
  @@store = nil

  def store
    if @store == nil
      @store = cassandra_client
      @store.use('measurements')
    end
    @store
  end

  def execute_query(query)
    exceptions = 0
    begin
      results = store.execute(query)
    rescue => e
      exceptions = exceptions + 1
      if (exceptions > 3)
        raise e
      else
        @store = nil
        retry
      end
    end
    results
  end

  def cassandra_client
    Cql::Client.connect(hosts: [CASSANDRA_HOST])
  end

  def set_base_timestamp(ts)
    query = "INSERT INTO Globals (name, value) VALUES ('%s', '%s')" % ["base_timestamp", ts.to_s]
    execute_query(query)
  end

  def get_base_timestamp
    query = "SELECT value FROM Globals WHERE name = '%s'" % ["base_timestamp"]
    results = execute_query(query)
    value = results.first["value"]
    raise "No base_timestamp set!" if value.nil?
    value.to_i
  end

  def record_metric(name, value)
    query = "INSERT INTO Metrics (name, value, when) VALUES ('%s', '%s', dateof(now()))" % [name, value]
    # query = "UPDATE Metrics SET 'when' = dateof(now()) WHERE KEY IN ('%s', '%s')" % [name, value]
    execute_query(query)
  end

  # It's convenient to initialize this here.
  def setup_cassandra
    puts "SETTING UP CASSANDRA..."

    client = cassandra_client

    # Don't drop and recreate the keyspace as that might disrupt (debug) clients
    # client.execute('DROP KEYSPACE IF EXISTS measurements')
    puts "> CREATING KEYSPACE"
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

      puts "> DROPPING TABLES"

      tables = [
        "InstantaneousPlugLoads",
        "AveragePlugLoads",
        "AverageHouseLoads",
        "Globals",
        "Metrics"
      ]

      tables.each do |table|
        begin
          client.execute("DROP TABLE IF EXISTS #{table}")
        rescue Cql::QueryError => e
          # nop
        end
      end

      #
      # TABLES
      #

      puts "> CREATING TABLES"

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
        CREATE TABLE AverageHouseLoads (
        house_id BIGINT,
        slice_index INT,
        load DOUBLE,
        predicted BOOLEAN,
        PRIMARY KEY (house_id, slice_index)
        )
      TABLEDEF
      client.execute(table_definition)

      table_definition = <<-TABLEDEF
        CREATE TABLE Globals (
        name VARCHAR,
        value VARCHAR,
        PRIMARY KEY (name)
        )
      TABLEDEF
      client.execute(table_definition)
      # client.add(table_definition)

      table_definition = <<-TABLEDEF
        CREATE TABLE Metrics (
        name VARCHAR,
        when TIMESTAMP,
        value VARCHAR,
        PRIMARY KEY (name, when)
        )
      TABLEDEF
      client.execute(table_definition)

      #
      # INDEXES
      #

      puts "> CREATING INDEXES"

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

      index_definition = <<-INDEXDEF
        CREATE INDEX AveragePlugLoadsSliceIndex ON
          AveragePlugLoads
          (slice_index)
      INDEXDEF
      client.execute(index_definition)

      index_definition = <<-INDEXDEF
        CREATE INDEX AverageHouseLoadsPredictedIndex ON
          AverageHouseLoads
          (predicted)
      INDEXDEF
      client.execute(index_definition)
    end
    client
  end

end
