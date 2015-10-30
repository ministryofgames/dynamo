defmodule Dynamo.AttributeType.Encoder do
  
  def encode(nil), do: [{"NULL", true}]
  def encode(%{:B => blob} = item) when map_size(item) == 1, do: {[{"B", Base.encode64(blob)}]}
  def encode(%{:NULL => is_null} = item) when map_size(item) == 1, do: {[{"NULL", is_null}]}
  def encode(%{:BOOL => bool} = item) when map_size(item) == 1, do: {[{"BOOL", bool}]}
  def encode(%{:N => number} = item) when map_size(item) == 1, do: {[{"N", number}]}
  def encode(%{:S => string} = item) when map_size(item) == 1, do: {[{"S", string}]}
  def encode(%{:M => map} = item) when map_size(item) == 1, do: {[{"M", encode(map)}]}
  def encode(item) when is_map(item), do: encode_map(item |> Map.to_list, [])
  def encode(item) when is_number(item), do: {[{"N", item |> to_string}]}
  def encode(item) when is_binary(item), do: {[{"S", item}]}
  def encode(item) when is_boolean(item), do: {[{"BOOL", item |> to_string}]}
  def encode(item) when is_list(item), do: encode_list(item, [])
  def encode(item) when is_atom(item), do: raise ArgumentError, "atoms not allowed"
  def encode(_item), do: raise ArgumentError, "unknown type"
  
  defp encode_map([], acc), do: {[{"M", acc}]}
  defp encode_map([{k, v} | rest], acc) do
    encode_map(rest, [{k, encode(v)} | acc])
  end
  
  defp encode_list([], acc), do: {[{"L", acc |> List.flatten |> Enum.reverse}]}
  defp encode_list([item | rest], acc) do
    encode_list(rest, [encode(item) | acc])
  end
  
end
