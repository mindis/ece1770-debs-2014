require 'red_storm'

class DebsPlugBolt < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers

  DEBUG = false

  configure do
    debug DEBUG
  end

  # input_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
  output_fields :timestamp, :house_id, :household_id, :plug_id, :predicted_load

  on_init do
    @slice_duration_in_seconds = 60
  end

  # emit is false because we're not always emitting
  on_receive :emit => false, :ack => false, :anchor => false do |tuple|
    @tuple = tuple
    if tuple_contains_load_value?
      update_real_load
      datum = [timestamp, house_id, household_id, plug_id, predict_load]
      anchored_emit(tuple, *datum)
    end
    ack(tuple)
  end

  def set_instantaneous_load(load, ts)
    if load == nil
      raise "Load is nil"
    end
    query = "INSERT INTO InstantaneousPlugLoads (house_id, household_id, plug_id, timestamp, load) VALUES (%d, %d, %d, %d, %f)" % 
      [house_id, household_id, plug_id, ts, load]
    store.execute(query)            
    puts "EXECUTED: #{query}" if DEBUG
  end

  def get_instantaneous_load(ts)
    query = "SELECT load FROM InstantaneousPlugLoads WHERE house_id = %d " \
      "AND household_id = %d "\
      "AND plug_id = %d "\
      "AND timestamp = %d" % [house_id, household_id, plug_id, ts]
    results = store.execute(query)
    if results.count != 1
      puts "Invalid number of results! #{results}"
      raise Exception
    end
    load = results.first["load"]
    puts "EXECUTED: #{query}, GOT #{load}" if DEBUG
    load
  end

  def get_instantaneous_loads_in_range(inclusive_from_ts, exclusive_to_ts)
    query = "SELECT load FROM InstantaneousPlugLoads WHERE house_id = %d " \
      "AND household_id = %d "\
      "AND plug_id = %d "\
      "AND timestamp >= %d AND timestamp < %d" % [house_id, household_id, plug_id, inclusive_from_ts, exclusive_to_ts]
    results = store.execute(query)
    puts "EXECUTED: #{query}, GOT #{results}" if DEBUG
    loads = results.map{|row| row["load"]}
  end

  def set_average_load_for_slice(load, slice_index, predicted = false)
    if load == nil
      raise "Load is nil"
    end

    query = "INSERT INTO AveragePlugLoads (house_id, household_id, plug_id, slice_index, load, predicted) VALUES (%d, %d, %d, %d, %f, #{predicted})" % 
      [house_id, household_id, plug_id, slice_index, load]
    store.execute(query)
    puts "EXECUTED: #{query}" if DEBUG
  end

  def get_average_load_for_slice(slice_index)
    query = "SELECT load FROM AveragePlugLoads WHERE house_id = %d " \
      "AND household_id = %d "\
      "AND plug_id = %d "\
      "AND slice_index = %d" % [house_id, household_id, plug_id, slice_index]
    results = store.execute(query)
    if results.count != 1
      puts "Invalid number of results for slice_index (#{slice_index})! #{results}"
      raise Exception
    end
    load = results.first["load"]
    puts "EXECUTED: #{query}, GOT #{load}" if DEBUG
    load
  end

  def invalidate_future_results
    i = slice_index

    # TODO
  end

  def update_real_load
    set_instantaneous_load(value, timestamp)

    # calculate the average load for the current slice
    start_time = round_down_timestamp
    end_time = round_up_timestamp
    # TODO: fill in missing data (linear interpolation?)
    instantaneous_loads_for_plug = get_instantaneous_loads_in_range(start_time, end_time)

    average_load_for_current_slice = instantaneous_loads_for_plug.inject(0){|sum,x| sum + x} / instantaneous_loads_for_plug.size

    set_average_load_for_slice(average_load_for_current_slice, slice_index)

    # invalidate any future slices (none should exist; do a sanity check)
    invalidate_future_results
  end

  def predict_load
    average_load_for_current_slice = get_average_load_for_slice(slice_index)

    # puts ">>> AVG_LOAD: #{average_load_for_current_slice}"

    i = slice_index
    k = number_of_slices_per_day
    other_slice_indexes = (1..((i + 2)/k).floor).to_a.map{|n| (i+2) - n*k}

    # puts "OTHER INDEXES (#{timestamp} -> #{round_down_timestamp}, #{i}, #{k}): #{other_slice_indexes}"

    # TODO: shunt this work to Cassandra
    average_loads_for_other_slices = other_slice_indexes.map{|j| get_average_load_for_slice(j)}

    predicted_load = (average_load_for_current_slice + median(average_loads_for_other_slices))/2
    set_average_load_for_slice(predicted_load, slice_index, true)
    predicted_load
  end

  def number_of_slices_per_day
    (24 * 60 * 60) / @slice_duration_in_seconds
  end

  def slice_index
    # TODO can we infer this from the stream?
    @rounded_down_base_timestamp = 1377986401 - (1377986401 % @slice_duration_in_seconds)

    ((round_down_timestamp - @rounded_down_base_timestamp) / @slice_duration_in_seconds).to_i
  end

end
