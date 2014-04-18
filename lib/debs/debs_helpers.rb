module DebsHelpers

  def id
    @tuple[:id]
  end

  def timestamp
    @tuple[:timestamp]
  end

  def property
    @tuple[:property]
  end

  def value
    @tuple[:value]
  end

  def house_id
    @tuple[:house_id]
  end

  def household_id
    @tuple[:household_id]
  end

  def plug_id
    @tuple[:plug_id]
  end

  def predicted_plug_load
    @tuple[:predicted_plug_load]
  end

  def round_down_timestamp(ts = timestamp)
    ts - (ts % slice_duration_in_seconds)
  end

  def round_up_timestamp(ts = timestamp)
    round_down_timestamp(ts) + slice_duration_in_seconds
  end

  def rounded_down_base_timestamp
    @rounded_down_base_timestamp ||= get_base_timestamp - (get_base_timestamp % slice_duration_in_seconds)
  end

  def slice_duration_in_seconds
    # TODO: hardcoded for now. Later, need to support different-sized slices.
    60
  end

  def number_of_slices_per_day
    (24 * 60 * 60) / slice_duration_in_seconds
  end

  def slice_index(ts = round_down_timestamp)
    # TODO: hardcoded slice_duration_in_seconds for now. Later, need to support 
    # different-sized slices (which means numerous indexes).
    ((round_down_timestamp(ts) - rounded_down_base_timestamp) / slice_duration_in_seconds).to_i
  end

  def tuple_contains_load_value?
    property == 1
  end

  def sum(array)
    array.inject(0){|s,i| s = s + i}
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

  def average(array)
    array.inject(0){|sum,x| sum + x} / array.size
  end

end