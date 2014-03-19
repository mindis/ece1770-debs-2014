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
require 'debs/debs_house_calc_bolt'

class KafkaTopology < RedStorm::DSL::Topology

  include CassandraHelpers

  spout_config = SpoutConfig.new(
    KafkaConfig::ZkHosts.new("192.168.50.3:2181", "/brokers"),
    "debs-1",        # topic to read from
    "/consumers",  # Zookeeper root path to store the consumer offsets
    "someid"       # Zookeeper consumer id to store the consumer offsets
  )

  spout KafkaSpout, [spout_config]

  bolt DebsDataBolt, :parallelism => 1 do
    output_fields :timestamp, :value, :property, :plug_id, :household_id, :house_id
    source KafkaSpout, :shuffle
    debug true
  end

  bolt DebsHouseBolt, :parallelism => 2 do
    output_fields :timestamp, :value, :property, :plug_id, :household_id, :house_id
    source DebsDataBolt, :fields => [:house_id]
  end

  bolt DebsHouseholdBolt, :parallelism => 2 do
    output_fields :timestamp, :value, :property, :plug_id, :household_id, :house_id
    source DebsHouseBolt, :fields => [:household_id]
  end

  bolt DebsPlugBolt, :parallelism => 2 do
    output_fields :timestamp, :house_id, :household_id, :plug_id, :predicted_load
    source DebsHouseholdBolt, :fields => [:plug_id]
  end

  bolt DebsHouseCalcBolt, :parallelism => 2 do
    output_fields :timestamp, :house_id, :predicted_load
    source DebsPlugBolt, :fields => [:house_id]
  end

  configure do |env|
    debug true
    max_task_parallelism 1
    num_workers 1
    max_spout_pending 1000
  end

  on_submit do |env|
    setup_cassandra

    # TODO: the spout should do this.
    set_base_timestamp(1377986401)

    if env == :local
      sleep(60)
      cluster.shutdown
    end
  end
end

