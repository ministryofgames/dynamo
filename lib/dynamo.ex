defmodule Dynamo do
	require Logger

  alias Dynamo.AttributeType.Encoder
  alias Dynamo.AttributeType.Decoder
  alias Dynamo.Http

  @doc ~S"""
  Creates a table to DynamoDB.

  ## Examples
  
      iex> attr_defs = [%{"AttributeName" => "test", "AttributeType" => "S"}]
      iex> key_schema = [%{"AttributeName" => "test", "KeyType" => "HASH"}]
      iex> throughput = %{"ReadCapacityUnits" => 1, "WriteCapacityUnits" => 1}
      iex> Dynamo.create_table("test", attr_defs, key_schema, throughput)
  """
  def create_table(name, attr_defs, key_schema, throughput, opts \\ %{}) do
    data = %{
      "TableName" => name,
      "AttributeDefinitions" => attr_defs,
      "KeySchema" => key_schema,
      "ProvisionedThroughput" => throughput
    }
    
    # add options
    data = Dict.merge(opts, data)
    
    case do_operation("CreateTable", data) do
      {:ok, result} ->
        {:ok, build_result(result)}
      {:error, error} ->
        {:error, error}
    end
  end
  
  @doc ~S"""
  Stores an item into DybamoDB table.

  ## Examples
  
      iex> item = %{"test" => "test"}
      iex> Dynamo.put_item("test", item)
  """
  def put_item(table, item, opts \\ %{}) do
    item = Enum.map(item, fn {k, v} -> {k, Encoder.encode(v)} end)
    data = %{
      "Item" => item,
      "TableName" => table
    }
    
    # add optional attribtues
    data = Dict.merge(opts, data)
    
    case do_operation("PutItem", data) do
      {:ok, {[]}} ->
        :ok
      {:error, error} ->
        {:error, error}
    end
  end

  @doc ~S"""
  Gets an item from DynamoDB table.

  ## Examples

      iex> key = %{"test" => "test"}
      iex> Dynamo.get_item("test", key)
  """
  def get_item(table, key, opts \\ %{}) do
    key = Enum.map(key, fn {k, v} -> {k, Encoder.encode(v)} end)
    data = %{
      "Key" => key,
      "TableName" => table
    }

    # add optional attributes
    data = Dict.merge(opts, data)

    case do_operation("GetItem", data) do
      {:ok, result} when map_size(result) == 0 ->
        {:error, :item_not_found}
      {:ok, {[]}} ->
        {:error, :item_not_found}
      {:ok, result} ->
        # build the response map
        {:ok, build_result(result)}
      {:error, error} ->
        {:error, error}
    end
  end

  @doc ~S"""
  Deletes an item from DynamoDB table.

  ## Examples

      iex> key = %{"__id__" => "test"}
      iex> Dynamo.delete_item("test_table", key)
  """
  def delete_item(table, key, opts \\ %{}) do
    key = Enum.map(key, fn {k, v} -> {k, Encoder.encode(v)} end)
    data = %{
      "Key" => key,
      "TableName" => table
    }

    data = Dict.merge(opts, data)

    case do_operation("DeleteItem", data) do
      {:ok, _result} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  ## Internal API

  defp do_operation(opname, data) do
    response = Http.post(opname, data)

    case response.status_code do
      200 -> {:ok, response.payload}
      _ -> {:error, map_error(response.payload)}
    end
  end

  defp map_error(payload) do
    # \todo [petri] http body is parsed as a tuple (and thus wrapped in a 1-element tuple)
    payload = build_result(payload)
    [_, err_type] = String.split(payload["__type"], "#", parts: 2)
    err_msg = payload["message"]

    case err_type do
      "ConditionalCheckFailedException" -> :conditional_check_failed
      "InternalServerError" -> :internal_server_error
      "ItemCollectionSizeLimitExceededException" -> :item_collection_size_limit_exceeded
      "ProvisionedThroughputExceededException" -> :provisioned_throughput_exceeded
      "ResourceNotFoundException" -> :resource_not_found
      other -> {other, err_msg}
    end
  end

  def build_result(result), do: build_result(result, %{})
  def build_result({map}, acc) do
    Enum.into(map, acc,
              fn
                {"Item", v} -> {"Item", build_items(v)}
                {k, v} -> {k, build_result(v, %{})}
              end)
  end
  def build_result(value, _acc) when is_list(value) do
    Enum.map(value, &build_result(&1, %{}))
  end
  def build_result(value, _acc), do: value

  defp build_items({items}) do
    Enum.into(items, %{}, fn {k, v} -> {k, Decoder.decode(v)} end)
  end
  
end
