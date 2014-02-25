require 'red_storm'
require 'redstorm-starter/debs_helpers'
require 'redstorm-starter/debs_data_spout'
require 'redstorm-starter/debs_house_bolt'
require 'redstorm-starter/debs_household_bolt'
require 'redstorm-starter/debs_plug_bolt'
require 'redstorm-starter/debs_house_calc_bolt'

class DebsTopology < RedStorm::DSL::Topology
  spout DebsDataSpout, :parallelism => 1 do
    output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
  end

  bolt DebsHouseBolt, :parallelism => 1 do
    output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
    source DebsDataSpout, :fields => [:house_id]
  end

  bolt DebsHouseholdBolt, :parallelism => 1 do
    output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
    source DebsHouseBolt, :fields => [:household_id]
  end

  bolt DebsPlugBolt, :parallelism => 1 do
    output_fields :id, :timestamp, :house_id, :household_id, :plug_id, :predicted_load
    source DebsHouseholdBolt, :fields => [:plug_id]
  end

  bolt DebsHouseCalcBolt, :parallelism => 1 do
    output_fields :timestamp, :house_id, :predicted_load
    source DebsPlugBolt, :fields => [:house_id]
  end

  configure do |env|
    debug true
    max_task_parallelism 1
    num_workers 1
    max_spout_pending 1000
  end
end
