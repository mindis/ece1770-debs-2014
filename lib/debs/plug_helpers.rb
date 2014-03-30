module PlugHelpers

  DEBUG = false

  def set_instantaneous_plug_load(ts, load)
    if load == nil
      raise "Load is nil"
    end
    s_i = slice_index(ts) # convenience for faster lookups
    query = "INSERT INTO InstantaneousPlugLoads (house_id, household_id, plug_id, timestamp, slice_index, load) VALUES (%d, %d, %d, %d, %d, %f)" % 
      [house_id, household_id, plug_id, ts, s_i, load]
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

  def invalidate_future_results
    i = slice_index
    # TODO
  end

  # "The value of avgLoad(s_i), in case of plug-based prediction, is calculated 
  # as the average of all load values reported by the given plug with 
  # timestamps in s_i."
  def get_plug_avgLoad(s_i, h_id = house_id, hh_id = household_id, p_id = plug_id)
    query = "SELECT load FROM AveragePlugLoads WHERE house_id = %d " \
      "AND household_id = %d "\
      "AND plug_id = %d "\
      "AND slice_index = %d" % [h_id, hh_id, p_id, s_i]
    results = store.execute(query)
    if results.count != 1
      puts "Invalid number of results for slice_index (#{s_i})! #{results.map{|r| [r]}}"
      raise Exception
    end
    load = results.first["load"]
    puts "EXECUTED: #{query}, GOT #{load}" if DEBUG
    load
  end

  def calculate_plug_avgLoad(s_i)
    # TODO: fill in missing data (linear interpolation?)
    query = "SELECT load FROM InstantaneousPlugLoads WHERE house_id = %d " \
      "AND household_id = %d "\
      "AND plug_id = %d "\
      "AND slice_index = %d" % [house_id, household_id, plug_id, s_i]
    results = store.execute(query)
    loads = results.map{|row| row["load"]}
    puts "EXECUTED: #{query}, GOT #{loads}" if DEBUG
    average(loads)
  end

  def set_plug_avgLoad(s_i, load, predicted = false)
    if load == nil
      raise "Load is nil"
    end
    query = "INSERT INTO AveragePlugLoads (house_id, household_id, plug_id, slice_index, load, predicted) VALUES (%d, %d, %d, %d, %f, #{predicted})" % 
      [house_id, household_id, plug_id, s_i, load]
    store.execute(query)
    puts "EXECUTED: #{query}" if DEBUG
  end

  def get_house_avgLoad(s_i, h_i = house_id)
    query = "SELECT load FROM AverageHouseLoads WHERE house_id = %d " \
      "AND slice_index = %d" % [h_i, s_i]
    results = store.execute(query)
    if results.count != 1
      puts "Invalid number of results for slice_index (#{s_i})! #{results.map{|r| [r]}}"
      raise Exception
    end
    load = results.first["load"]
    puts "EXECUTED: #{query}, GOT #{load}" if DEBUG
    load
  end

  # "In case of a house-based prediction the avgLoad(s_i) is calculated as a sum 
  # of average values for each plug within the house."
  def calculate_house_avgLoad(s_i)
    query = "SELECT load FROM AveragePlugLoads WHERE house_id = %d " \
      "AND slice_index = %d" % [house_id, s_i]

    results = store.execute(query)
    loads = results.map{|row| row["load"]}
    puts "EXECUTED: #{query}, GOT #{loads}" if DEBUG
    sum(loads)
  end

  def set_house_avgLoad(s_i, load, predicted = false)
    if load == nil
      raise "Load is nil"
    end
    query = "INSERT INTO AverageHouseLoads (house_id, slice_index, load, predicted) VALUES (%d, %d, %f, #{predicted})" % 
      [house_id, s_i, load]
    store.execute(query)
    puts "EXECUTED: #{query}" if DEBUG
  end

  # avgLoad(s_j) } is a set of average load values for all slices s_j such that:
  #     s_j = s_(i + 2 – n*k )
  # where k is the number of slices in a 24 hour period, n is a natural number 
  # with values between 1 and floor((i + 2)/k).

  def s_j(i = slice_index) # historical slice indexes
    k = number_of_slices_per_day
    other_slice_indexes = (1..((i + 2)/k).floor).to_a.map{|n| (i+2) - n*k}
  end

  def plug_historical_avgLoads(s_i)
    indexes = s_j(s_i)
    query = "SELECT load FROM AveragePlugLoads WHERE house_id = %d " \
      "AND household_id = %d "\
      "AND plug_id = %d "\
      "AND slice_index IN (%s)" % [house_id, household_id, plug_id, indexes.join(",")]
    results = store.execute(query)
    loads = results.map{|row| row["load"]}
    puts "EXECUTED: #{query}, GOT #{loads}" if DEBUG
    loads
  end

  # Called when a new tuple arrives at the plug_bolt
  def update_current_plug_load
    set_instantaneous_plug_load(timestamp, value)

    s_i = slice_index
    load = calculate_plug_avgLoad(s_i)
    set_plug_avgLoad(s_i, load)

    # invalidate any future slices (none should exist; do a sanity check)
    invalidate_future_results
  end

  def update_current_house_load
    s_i = slice_index
    load= calculate_house_avgLoad(s_i)
    set_house_avgLoad(s_i, load)

    # invalidate any future slices (none should exist; do a sanity check)
    invalidate_future_results
  end

  def calculate_predicted_load(avg_load, historical_loads)
    (avg_load + median(historical_loads)) / 2
  end

  # NOTE: "The value of the { avgLoad(s_j) } is calculated analogously to 
  # avgLoad(s_i) in case of plug-based and house-based (sum of averages) 
  # variants.

  def predict_plug_load
    s_i = slice_index
    historical_slice_indexes = s_j(s_i)
    average_load_for_current_slice = get_plug_avgLoad(s_i)
    average_loads_for_other_slices = historical_slice_indexes.map{|j| get_plug_avgLoad(j)}
    predicted_load = calculate_predicted_load(average_load_for_current_slice, average_loads_for_other_slices)
    set_plug_avgLoad(s_i + 2, predicted_load, true)
    predicted_load
  end

  def predict_house_load
    s_i = slice_index
    historical_slice_indexes = s_j(s_i)
    average_load_for_current_slice = get_house_avgLoad(s_i)
    average_loads_for_other_slices = historical_slice_indexes.map{|j| get_house_avgLoad(j)}
    predicted_load = calculate_predicted_load(average_load_for_current_slice, average_loads_for_other_slices)
    set_house_avgLoad(s_i + 2, predicted_load, true)
    predicted_load
  end

end