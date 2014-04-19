java_import 'storm.kafka.SpoutConfig'
java_import 'storm.kafka.KafkaSpout'
java_import 'storm.kafka.KafkaConfig'
java_import 'storm.kafka.ZkHosts'

require 'red_storm'
require 'debs/debs_helpers'
require 'debs/cassandra_helpers'
require 'debs/plug_helpers'
require 'debs/debs_data_bolt'
require 'debs/debs_house_bolt'
require 'debs/debs_household_bolt'
require 'debs/debs_plug_bolt'
require 'debs/debs_plug_bolt2'
require 'debs/debs_house_calc_bolt'
require 'debs/debs_house_calc_bolt2'
require 'debs/debs_dummy_client_bolt'

class KafkaTopology < RedStorm::DSL::Topology

  include CassandraHelpers

  ZOOKEEPER="192.168.50.3:2181"

  spout_config = SpoutConfig.new(
    KafkaConfig::ZkHosts.new(ZOOKEEPER, "/brokers"),
    "debs-1",      # topic to read from
    "/consumers",  # Zookeeper root path to store the consumer offsets
    "someid"       # Zookeeper consumer id to store the consumer offsets
  )

  spout KafkaSpout, [spout_config]

  bolt DebsDataBolt, :parallelism => 1 do
    output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
    source KafkaSpout, :shuffle
    debug false
  end

  bolt DebsHouseBolt, :parallelism => 1 do
    output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
    source DebsDataBolt, :fields => [:house_id]
  end

  bolt DebsHouseholdBolt, :parallelism => 2 do
    output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
    source DebsHouseBolt, :fields => [:household_id]
  end

  ###
  # In Vagrant, anything past here causes failed tuples due to high latency (>= 30s)
  ###

  bolt DebsPlugBolt, :parallelism => 8 do
    output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
    source DebsHouseholdBolt, :fields => [:plug_id]
  end

  bolt DebsPlugBolt2, :parallelism => 8 do
    output_fields :id, :timestamp, :house_id, :household_id, :plug_id, :predicted_plug_load
    source DebsPlugBolt, :fields => [:plug_id]
  end

  bolt DebsHouseCalcBolt, :parallelism => 8 do
    output_fields :id, :timestamp, :house_id, :household_id, :plug_id, :predicted_plug_load
    source DebsPlugBolt2, :fields => [:house_id]
  end

  bolt DebsHouseCalcBolt2, :parallelism => 8 do
    output_fields :id, :timestamp, :house_id, :predicted_house_load
    source DebsHouseCalcBolt, :fields => [:house_id]
  end

  bolt DebsDummyClientBolt, :parallelism => 1 do
    output_fields :id, :timestamp
    source DebsHouseCalcBolt2, :global
  end

  configure do |env|
    debug false
    max_task_parallelism 4
    num_workers 2
    max_spout_pending 100 # 16000
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

