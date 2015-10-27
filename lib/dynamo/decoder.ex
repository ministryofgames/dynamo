defmodule Dynamo.Decoder do

  def decode(item) do
    decode_item(item)
  end

  defp decode_item(%{"NULL" => true}),  do: nil
  defp decode_item(%{"BOOL" => value}), do: value == "true"
  defp decode_item(%{"S" => value}),    do: value
  defp decode_item(%{"N" => value}),    do: decode_number(value)
  defp decode_item(%{"M" => value}),    do: decode_map(value)
  defp decode_item(%{"L" => value}),    do: decode_list(value)

  defp decode_number(string) do
    try do
      String.to_float(string)
    rescue
      ArgumentError ->
        String.to_integer(string)
    end
  end
                                   
  defp decode_map(map) do
    Enum.reduce(map, %{}, fn ({k, v}, acc) ->
      Dict.put(acc, k, decode_item(v))
    end)
  end

  defp decode_list(list) do
    Enum.map(list, &decode_item(&1))
  end
  
end
