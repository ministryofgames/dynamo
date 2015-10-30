defmodule Dynamo.AttributeType.Decoder do

  def decode({[{"NULL", true}]}),  do: nil
  def decode({[{"BOOL", value}]}), do: value == "true"
  def decode({[{"B", value}]}),    do: Base.decode64!(value)
  def decode({[{"S", value}]}),    do: value
  def decode({[{"N", value}]}),    do: decode_number(value)
  def decode({[{"M", value}]}),    do: decode_map(value)
  def decode({[{"L", value}]}),    do: decode_list(value)

  defp decode_number(string) do
    try do
      String.to_float(string)
    rescue
      ArgumentError ->
        String.to_integer(string)
    end
  end
                                   
  defp decode_map({map}) do
    Enum.reduce(map, %{}, fn ({k, v}, acc) ->
      Dict.put(acc, k, decode(v))
    end)
  end
  
  defp decode_list(list) do
    Enum.map(list, &decode(&1))
  end
  
end
