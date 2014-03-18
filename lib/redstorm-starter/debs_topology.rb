java_import 'storm.kafka.SpoutConfig'
java_import 'storm.kafka.KafkaSpout'
java_import 'storm.kafka.KafkaConfig'
java_import 'storm.kafka.ZkHosts'

require 'red_storm'
# require 'redstorm-starter/debs_helpers'
# require 'redstorm-starter/debs_data_spout'
# require 'redstorm-starter/debs_house_bolt'
# require 'redstorm-starter/debs_household_bolt'
# require 'redstorm-starter/debs_plug_bolt'
# require 'redstorm-starter/debs_house_calc_bolt'

class SplitStringBolt < RedStorm::DSL::Bolt
  on_receive do |tuple|
    tuple[0].to_s.split.map{|w| [w]}
  end
end

class KafkaTopology < RedStorm::DSL::Topology

  spout_config = SpoutConfig.new(
    KafkaConfig::ZkHosts.new("192.168.50.3:2181", "/brokers"),
    "testtopic",   # topic to read from
    "/consumers",  # Zookeeper root path to store the consumer offsets
    "someid"       # Zookeeper consumer id to store the consumer offsets
  )

  spout KafkaSpout, [spout_config]

  bolt SplitStringBolt do
    output_fields :word
    source KafkaSpout, :shuffle
    debug true
  end

  configure do |env|
    debug true
    max_task_parallelism 1
    num_workers 1
    max_spout_pending 1000
  end

  on_submit do |env|
    if env == :local
      sleep(60)
      cluster.shutdown
    end
  end
end


# class DebsTopology < RedStorm::DSL::Topology

#   DEBUG = false

#   configure do |env|
#     debug DEBUG
#     max_task_parallelism 8
#     num_workers 8
#     max_spout_pending 1000
#   end

#   spout DebsDataSpout, :parallelism => 1 do
#     output_fields :timestamp, :value, :property, :plug_id, :household_id, :house_id
#   end

#   bolt DebsHouseBolt, :parallelism => 2 do
#     output_fields :timestamp, :value, :property, :plug_id, :household_id, :house_id
#     source DebsDataSpout, :fields => [:house_id]
#   end

#   bolt DebsHouseholdBolt, :parallelism => 2 do
#     output_fields :timestamp, :value, :property, :plug_id, :household_id, :house_id
#     source DebsHouseBolt, :fields => [:household_id]
#   end

#   bolt DebsPlugBolt, :parallelism => 2 do
#     output_fields :timestamp, :house_id, :household_id, :plug_id, :predicted_load
#     source DebsHouseholdBolt, :fields => [:plug_id]
#   end

#   bolt DebsHouseCalcBolt, :parallelism => 2 do
#     output_fields :timestamp, :house_id, :predicted_load
#     source DebsPlugBolt, :fields => [:house_id]
#   end

#   on_submit do |env|
#     if env == :local
#       sleep(60)
#       cluster.shutdown
#     end
#   end

# end
