java_import 'storm.kafka.SpoutConfig'
java_import 'storm.kafka.KafkaSpout'
java_import 'storm.kafka.KafkaConfig'
java_import 'storm.kafka.ZkHosts'

require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'
require 'debs/debs_data_bolt'
require 'debs/debs_plug_bolt'
require 'debs/debs_plug_bolt2'
require 'debs/debs_house_calc_bolt'
require 'debs/debs_house_calc_bolt2'
require 'debs/debs_dummy_client_bolt'

class KafkaTopology < RedStorm::DSL::Topology

  include CassandraHelpers

  ZOOKEEPER="54.86.69.25:2181"

  spout_config = SpoutConfig.new(
    KafkaConfig::ZkHosts.new(ZOOKEEPER, "/brokers"),
    "debs-6",      # topic to read from
    "/consumers",  # Zookeeper root path to store the consumer offsets
    "someid"       # Zookeeper consumer id to store the consumer offsets
  )

  spout KafkaSpout, [spout_config]

  bolt DebsDataBolt, :parallelism => 1 do
    output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id, :start_time
    source KafkaSpout, :shuffle
    debug false
    max_task_parallelism 1
  end

  bolt DebsPlugBolt, :parallelism => 8 do
    output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id, :start_time
    source DebsDataBolt, :fields => [:house_id, :household_id, :plug_id]
    max_task_parallelism 8
  end

  bolt DebsPlugBolt2, :parallelism => 8 do
    output_fields :id, :timestamp, :house_id, :household_id, :plug_id, :predicted_plug_load, :start_time
    source DebsPlugBolt, :fields => [:house_id, :household_id, :plug_id]
    max_task_parallelism 8
  end

  bolt DebsHouseCalcBolt, :parallelism => 8 do
    output_fields :id, :timestamp, :house_id, :household_id, :plug_id, :predicted_plug_load, :start_time
    source DebsPlugBolt2, :fields => [:house_id]
    max_task_parallelism 8
  end

  bolt DebsHouseCalcBolt2, :parallelism => 8 do
    output_fields :id, :timestamp, :house_id, :predicted_house_load, :start_time
    source DebsHouseCalcBolt, :fields => [:house_id]
    max_task_parallelism 8
  end

  bolt DebsDummyClientBolt, :parallelism => 1 do
    output_fields :id, :timestamp, :start_time, :end_time
    source DebsHouseCalcBolt2, :global
    max_task_parallelism 1
  end

  configure do |env|

    # NOTE: machines (4) -> num_workers (x2 = 8) -> executors (parallalism hint) -> tasks (executors)
    # The number of workers and executors can be "rebalanced" (i.e. only reduced), but not the number of tasks.
    # The 'parallelism' hint above specifies the initial number of executors (and tasks). It's 1:1 by default.

    # redstorm creates 4 worker 'slots' for each machine by default
    # The config below specifies how many should be used by this topology.

    debug false
    max_task_parallelism 8
    num_workers 8 # <-- how many slots to use. up to 4 per machine, but keep it at 2 (1 per CPU on m1.large)
    max_spout_pending 10000 # 16000
  end

  on_submit do |env|

    if env == :local
      setup_cassandra
      
      # TODO: the spout should do this.
      set_base_timestamp(1377986401)

      sleep(60)
      cluster.shutdown
    end
  end
end

