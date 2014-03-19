module PlugHelpers

  DEBUG = false

  def set_instantaneous_plug_load(load, ts)
    if load == nil
      raise "Load is nil"
    end
    query = "INSERT INTO InstantaneousPlugLoads (house_id, household_id, plug_id, timestamp, load) VALUES (%d, %d, %d, %d, %f)" % 
      [house_id, household_id, plug_id, ts, load]
    store.execute(query)            
    puts "EXECUTED: #{query}" if DEBUG
  end

  def get_instantaneous_plug_load(ts)
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

  def get_instantaneous_plug_loads_in_range(inclusive_from_ts, exclusive_to_ts)
    query = "SELECT load FROM InstantaneousPlugLoads WHERE house_id = %d " \
      "AND household_id = %d "\
      "AND plug_id = %d "\
      "AND timestamp >= %d AND timestamp < %d" % [house_id, household_id, plug_id, inclusive_from_ts, exclusive_to_ts]
    results = store.execute(query)
    puts "EXECUTED: #{query}, GOT #{results}" if DEBUG
    loads = results.map{|row| row["load"]}
  end

  def set_average_plug_load_for_slice(load, slice_index, predicted = false)
    if load == nil
      raise "Load is nil"
    end
    query = "INSERT INTO AveragePlugLoads (house_id, household_id, plug_id, slice_index, load, predicted) VALUES (%d, %d, %d, %d, %f, #{predicted})" % 
      [house_id, household_id, plug_id, slice_index, load]
    store.execute(query)
    puts "EXECUTED: #{query}" if DEBUG
  end

  def get_average_plug_load_for_slice(slice_index)
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
end