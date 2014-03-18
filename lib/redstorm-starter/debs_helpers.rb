module DebsHelpers

  # def id
  #   @tuple[:id]
  # end

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

  def round_down_timestamp
    timestamp - (timestamp % @slice_duration_in_seconds)
  end

  def round_up_timestamp
    round_down_timestamp + @slice_duration_in_seconds
  end

  def tuple_contains_load_value?
    property == 1
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

end