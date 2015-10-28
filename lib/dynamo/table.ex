defmodule Dynamo.Table do

  alias Dynamo.Http
  
  defmodule KeySchema do
    @type dynamo_key_type :: :hash | :range
    
    defstruct attr_name: nil, key_type: nil
    @type t :: %KeySchema{attr_name: String.t, key_type: dynamo_key_type}
  end
  
  defmodule AttributeDefinition do
    @type dynamo_type :: :string | :number | :binary
    
    defstruct name: nil, type: nil
    @type t :: %AttributeDefinition{name: String.t, type: dynamo_type}
  end

  defmodule AttributeDefinitions do
    defstruct value: []
    @type t :: %AttributeDefinitions{value: [AttributeDefinition.t]}
  end

  defmodule GlobalSecondaryIndexes do
    defstruct value: []
    @type t :: %GlobalSecondaryIndexes{value: [SecondaryIndex.t]}
  end
  
  defmodule Projection do
    defstruct non_key_attrs: [], type: nil
    @type t :: %Projection{non_key_attrs: [String.t], type: String.t}
  end
  
  defmodule SecondaryIndex do
    defstruct name: nil, key_schema: nil, projection: nil, throughput: nil
    @type t :: %SecondaryIndex{name: String.t, key_schema: KeySchema.t,
                               projection: Projection.t,
                               throughput: [read: pos_integer, write: pos_integer]}
  end
  
  defmodule Spec do
    defstruct(name: nil, attr_defs: [], gsis: [], lsis: [], key_schema: nil,
              throughput: [read: 1, write: 1], stream_spec: %{})
    @type t :: %Spec{name: String.t, attr_defs: [AttrDef.t],
                     gsis: list, lsis: list, key_schema: [KeySchema.t],
                     throughput: [read: pos_integer, write: pos_integer],
                     stream_spec: Map.t}
  end


  @doc ~S"""
  Create a table in DynamoDb.
  
  ## Example

      iex> alias Dynamo.Table
      iex> attr1 = %Table.AttrDef{name: "Attr1", type: :string}
      iex> key_schema = [%Table.KeySchema{attr_name: "Attr1", key_type: :hash}]
      iex> Table.create("TestTable", [attr1], key_schema, [])
      :ok
  """
  def create(name, attr_defs, key_schema, opts) do
    throughput  = Keyword.get(opts, :throughput, [read: 1, write: 1])
    gsis        = Keyword.get(opts, :gsis, [])
    lsis        = Keyword.get(opts, :lsis, [])
    stream_spec = Keyword.get(opts, :stream_spec, %{})
    
    spec = %Spec{name: name, attr_defs: attr_defs, key_schema: key_schema,
                 gsis: gsis, lsis: lsis, throughput: throughput,
                 stream_spec: stream_spec}

    data = %{
      "AttributeDefinitions": get_attr_defs(spec),
      "KeySchema": get_key_schema(spec),
      "ProvisionedThroughput": get_throughput(spec),
      "TableName": spec.name
    }

    # add global secondary indexes
    gsis_spec = get_indexes(:gsi, spec)
    if gsis_spec != [] do
      data = Map.put(data, "GlobalSecondaryIndexes", gsis_spec)
    end

    # add local secondary indexes
    lsis_spec = get_indexes(:lsi, spec)
    if lsis_spec != [] do
      data = Map.put(data, "LocalSecondaryIndexes", lsis_spec)
    end
    
    do_operation("CreateTable", data)
  end
  
  def put_item(table, item, opts \\ %{}) do
    item = Enum.map(item, fn {k, v} -> {k, Dynamo.Encoder.encode(v)} end)
    data = %{
      "Item" => item,
      "TableName" => table
    }
    
    # add optional attribtues
    data = Dict.merge(opts, data)
    
    case do_operation("PutItem", data) do
      {:ok, %{}} ->
        :ok
      {:error, error} ->
        {:error, error}
    end
  end

  def get_item(table, key, consistent \\ true) do
    key = Enum.map(key, fn {k, v} -> {k, Dynamo.Encoder.encode(v)} end)
    data = %{
      "Key" => key,
      "TableName" => table,
      "ReturnConsumedCapacity" => "NONE"
    }

    case do_operation("GetItem", data) do
      {:ok, result} when map_size(result) == 0 ->
        {:error, :item_not_found}
      {:ok, result} ->
        item = Enum.into(result["Item"], %{}, fn {k, v} -> {k, Dynamo.Decoder.decode(v)} end)
        {:ok, Dict.put(result, "Item", item)}
      {:error, error} ->
        {:error, error}
    end
  end
  
  ## Internal API

  defp get_attr_defs(%{attr_defs: attr_defs}) do
    Enum.map(attr_defs, fn attr_def ->
      %{"AttributeName": attr_def.name, "AttributeType": get_dynamo_type attr_def.type}
    end)
  end

  defp get_indexes(:gsi, spec), do: get_index_spec(spec.gsis)
  defp get_indexes(:lsi, spec), do: get_index_spec(spec.lsis)
 
  defp get_index_spec(spec) do
    Enum.map(spec, fn gsi ->
      %{"IndexName": gsi.name, "KeySchema": get_key_schema(gsi),
        "Projection": %{"NonKeyAttributes": gsi.projection.non_key_attrs,
                        "ProjectionType": gsi.projection.type},
        "ProvisionedThroughPut": get_throughput(gsi)}
    end)
  end

  defp get_key_schema(%{key_schema: key_schema}) do
    Enum.map(key_schema, fn elem ->
      %{"AttributeName": elem.attr_name, "KeyType": get_dynamo_key_type(elem.key_type)}
    end)
  end
  
  defp get_throughput(%{throughput: throughput}) do
    %{"ReadCapacityUnits": throughput[:read],
      "WriteCapacityUnits": throughput[:write]}
  end

  defp get_dynamo_type(:string),  do: "S"
  defp get_dynamo_type(:number),  do: "N"
  defp get_dynamo_type(:binary),  do: "B"

  defp get_dynamo_key_type(:hash),  do: "HASH"
  defp get_dynamo_key_type(:range), do: "RANGE"

  defp create_table_payload([], acc), do: :jsone.encode(acc)
  defp create_table_payload([item|rest], acc) do
    acc = create_table_item(item, acc)
    create_table_payload(rest, acc)
  end

  defp create_table_item(%KeySchema{attr_name: attr_name, key_type: key_type}) do
    %{"AttributeName": attr_name, "KeyType": key_type}
  end
  
  defp create_table_item(%AttributeDefinition{name: name, type: type}) do
    %{"AttributeName": name, "AttributeType": type}
  end

  defp create_table_item(%SecondaryIndex{name: name, key_schema: key_schema,
                                         projection: projection, throughput: throughput}) do
    %{"IndexName": name,
      "KeySchema": Enum.map(key_schema, &create_table_item(&1)),
      "Projection": create_table_item(projection),
      "ProvisionedThroughput": create_table_item(throughput)}
  end
  
  
  defp create_table_item(%AttributeDefinitions{value: value}, acc) do
    Dict.put(acc, "AttributeDefinitions", Enum.map(value, &create_table_item(&1)))
  end

  defp do_operation(opname, data) do
    payload_str = :jsone.encode(data)
    response    = Http.post(opname, payload_str)
    
    case response.status_code do
      200 ->
        {:ok, response.payload}
      _ ->
        [_, type] = String.split(response.payload["__type"], "#", parts: 2)
        msg  = response.payload["message"]
        {:error, {type, msg}}
    end
  end
  
end
