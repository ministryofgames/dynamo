defmodule Dynamo.Encoder do

  def encode(item) do
    encode_item(item)
  end

  defp encode_item(nil),                        do: %{"NULL" => true}
  defp encode_item(:null),                      do: %{"NULL" => true}
  defp encode_item(item) when is_boolean(item), do: %{"BOOL" => item |> to_string}
  defp encode_item(item) when is_binary(item),  do: %{"S" => item}
  defp encode_item(item) when is_number(item),  do: %{"N" => item |> to_string}
  defp encode_item(item) when is_map(item),     do: encode_map(item |> Map.to_list, [])
  defp encode_item(item) when is_list(item),    do: encode_list(item, [])
  defp encode_item(item) when is_atom(item),    do: {:error, :atoms_not_supported}
  defp encode_item(item),                       do: {:error, :unknown_data_type}
  
  defp encode_kv({:error, error}), do: {:error, error}
  defp encode_kv({key, value}) when not is_binary(key), do: encode_kv({key |> to_string, value})
  defp encode_kv({key, value}) do
    case encode_item(value) do
      {:error, error} ->
        {:error, error}
      item ->
        {key, item}
    end
  end
  
  defp encode_map([], acc), do: %{"M" => Enum.into(acc, %{})}
  defp encode_map([kv | rest], acc) do
    case encode_kv(kv) do
      {:error, error} ->
        {:error, error}
      item ->
        encode_map(rest, [item | acc])
    end
  end

  defp encode_list([], acc), do: %{"L" => acc}
  defp encode_list([item | rest], acc) do
    case encode_item(item) do
      {:error, error} ->
        {:error, error}
      item ->
        encode_list(rest, [item | acc])
    end
  end
  
end
