require 'red_storm'

class DebsPlugBolt < RedStorm::DSL::Bolt

  include DebsHelpers
  include CassandraHelpers
  include PlugHelpers

  DEBUG = false

  configure do
    debug DEBUG
  end

  # input_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
  output_fields :timestamp, :house_id, :household_id, :plug_id, :predicted_load

  on_init do
    # nop
  end

  # emit is false because we're not always emitting
  on_receive :emit => false, :ack => false, :anchor => false do |tuple|
    @tuple = tuple
    if tuple_contains_load_value?
      update_real_plug_load
      datum = [timestamp, house_id, household_id, plug_id, predict_plug_load]
      anchored_emit(tuple, *datum)
    end
    ack(tuple)
  end

  def invalidate_future_results
    i = slice_index

    # TODO
  end

  def update_real_plug_load
    set_instantaneous_plug_load(value, timestamp)

    # calculate the average load for the current slice
    start_time = round_down_timestamp
    end_time = round_up_timestamp
    # TODO: fill in missing data (linear interpolation?)
    instantaneous_loads_for_plug = get_instantaneous_plug_loads_in_range(start_time, end_time)

    average_load_for_current_slice = instantaneous_loads_for_plug.inject(0){|sum,x| sum + x} / instantaneous_loads_for_plug.size

    set_average_plug_load_for_slice(average_load_for_current_slice, slice_index)

    # invalidate any future slices (none should exist; do a sanity check)
    invalidate_future_results
  end

  def predict_plug_load
    average_load_for_current_slice = get_average_plug_load_for_slice(slice_index)

    # puts ">>> AVG_LOAD: #{average_load_for_current_slice}"

    i = slice_index
    k = number_of_slices_per_day
    other_slice_indexes = (1..((i + 2)/k).floor).to_a.map{|n| (i+2) - n*k}

    # puts "OTHER INDEXES (#{timestamp} -> #{round_down_timestamp}, #{i}, #{k}): #{other_slice_indexes}"

    # TODO: shunt this work to Cassandra
    average_loads_for_other_slices = other_slice_indexes.map{|j| get_average_plug_load_for_slice(j)}

    predicted_load = (average_load_for_current_slice + median(average_loads_for_other_slices))/2
    set_average_plug_load_for_slice(predicted_load, slice_index, true)
    predicted_load
  end

end
