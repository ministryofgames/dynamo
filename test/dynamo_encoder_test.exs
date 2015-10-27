defmodule DynamoEncoderTest do
  use ExUnit.Case
  doctest Dynamo.Encoder
  
  alias Dynamo.Encoder

  test "encode boolean" do
    assert %{"BOOL" => "true"} == Encoder.encode(true)
    assert %{"BOOL" => "false"} == Encoder.encode(false)
  end

  test "encode atom" do
    assert {:error, :atoms_not_supported} == Encoder.encode(:atom)
  end
  
  test "encode string" do
    assert %{"S" => "string"} == Encoder.encode("string")
  end
  
  test "encode integer" do
    assert %{"N" => "10"} == Encoder.encode(10)
  end
  
  test "encode simple map" do
    assert %{"M" => %{"key" => %{"S" => "value"}}} == Encoder.encode(%{"key": "value"})
  end
  
  test "encode atom in nested map" do
    assert {:error, :atoms_not_supported} == Encoder.encode(%{"key1" => %{"key2" => :atom}})
  end

  test "encode list" do
    assert %{"L" => [%{"N" => "10"}, %{"S" => "string"}]} == Encoder.encode(["string", 10])
  end

  test "encode null" do
    assert %{"NULL" => true} == Encoder.encode(nil)
  end
  
end
