require 'red_storm'

class DebsPlugBolt < RedStorm::DSL::Bolt

  include DebsHelpers

  # input_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id
  output_fields :id, :timestamp, :house_id, :household_id, :plug_id, :predicted_load

  configure do
    debug true
  end

  on_init do
    @instantaneous_load = {} # :house_id, :household_id, :plug_id => :timestamp => :value
    @average_load = {} # :house_id, :household_id, :plug_id, :slice_index => :value
    @slice_duration_in_seconds = 60
  end

  # emit is false because we're not always emitting
  on_receive :emit => false, :ack => false, :anchor => false do |tuple|
    @tuple = tuple
    if tuple_contains_load_value?
      initialize_results
      update_real_load
      load = predict_load
      datum = [id, timestamp, house_id, household_id, plug_id, load]
      anchored_emit(tuple, *datum)
    end
    ack(tuple)
  end

  def initialize_results
    @instantaneous_load[house_id] ||= {}
    @instantaneous_load[house_id][household_id] ||= {}
    @instantaneous_load[house_id][household_id][plug_id] ||= {}

    @average_load[house_id] ||= {}
    @average_load[house_id][household_id] ||= {}
    @average_load[house_id][household_id][plug_id] ||= {}
  end

  def invalidate_future_results
    i = slice_index

    # TODO
  end

  def update_real_load
    @instantaneous_load[house_id][household_id][plug_id][timestamp] = value

    # calculate the average load for the current slice
    start_time = round_down_timestamp
    end_time = round_up_timestamp
    # TODO: fill in missing data (linear interpolation?)
    instantaneous_loads_for_plug = @instantaneous_load[house_id][household_id][plug_id].select do |k,v|
      k >= start_time && k < end_time
    end.map{|k,v| v}

    average_load_for_current_slice = instantaneous_loads_for_plug.inject(0){|sum,x| sum + x} / instantaneous_loads_for_plug.size
    @average_load[house_id][household_id][plug_id][slice_index] = average_load_for_current_slice

    # invalidate any future slices (none should exist; do a sanity check)
    invalidate_future_results
  end

  def predict_load
    average_load_for_current_slice = @average_load[house_id][household_id][plug_id][slice_index]

    # puts ">>> AVG_LOAD: #{average_load_for_current_slice}"

    i = slice_index
    k = number_of_slices_per_day
    other_slice_indexes = (1..((i + 2)/k).floor).to_a.map{|n| (i+2) - n*k}

    # puts "OTHER INDEXES (#{timestamp} -> #{round_down_timestamp}, #{i}, #{k}): #{other_slice_indexes}"

    average_loads_for_other_slices = other_slice_indexes.map{|j| @average_load[house_id][household_id][plug_id][j]}

    predicted_load = (average_load_for_current_slice + median(average_loads_for_other_slices))/2
    @average_load[house_id][household_id][plug_id][i+2] = predicted_load
  end

  def median(array)
    array = array.compact
    if array.size == 0
      return 0
    end
    sorted = array.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def number_of_slices_per_day
    (24 * 60 * 60) / @slice_duration_in_seconds
  end

  def tuple_contains_load_value?
    property == 1
  end

  def round_down_timestamp
    timestamp - (timestamp % @slice_duration_in_seconds)
  end

  def round_up_timestamp
    round_down_timestamp + @slice_duration_in_seconds
  end

  def slice_index
    # TODO can we infer this from the stream?
    @rounded_down_base_timestamp = 1377986401 - (1377986401 % @slice_duration_in_seconds)

    ((round_down_timestamp - @rounded_down_base_timestamp) / @slice_duration_in_seconds).to_i
  end

end
