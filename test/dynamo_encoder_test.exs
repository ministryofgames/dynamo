defmodule DynamoEncoderTest do
  use ExUnit.Case
  doctest Dynamo.AttributeType.Encoder
  
  alias Dynamo.AttributeType.Encoder

  test "encode boolean" do
    assert {[{"BOOL", "true"}]}  == Encoder.encode(true)
    assert {[{"BOOL", "false"}]} == Encoder.encode(false)
  end

  test "encode atom" do
    assert_raise ArgumentError, "atoms not allowed", fn ->
      Encoder.encode(:atom)
    end
  end
  
  test "encode string" do
    assert {[{"S", "string"}]} == Encoder.encode("string")
  end
  
  test "encode integer" do
    assert {[{"N", "10"}]} == Encoder.encode(10)
  end
  
  test "encode simple map" do
    assert {[{"M", [{"key", {[{"S", "value"}]}}]}]} == Encoder.encode(%{"key" => "value"})
  end
  
  test "encode atom in nested map" do
    assert_raise ArgumentError, "atoms not allowed", fn ->
      Encoder.encode(%{"key1" => %{"key2" => :atom}})
    end
  end

  test "encode list" do
    assert {[{"L", [{[{"S", "string"}]}, {[{"N", "10"}]}]}]} == Encoder.encode(["string", 10])
  end

  test "encode null" do
    assert [{"NULL", true}] == Encoder.encode(nil)
  end

  test "predefined types" do
    assert {[{"B", "dGVzdA=="}]}          == Encoder.encode(%{:B => "test"})
    assert {[{"NULL", true}]}             == Encoder.encode(%{:NULL => true})
    assert {[{"M", {[{"S", "string"}]}}]} == Encoder.encode(%{:M => %{:S => "string"}})
  end

  test "complex map" do
    map = %{"key1" => "value",
            "binary" => %{:B => "test"},
            "key2" => [%{"item1" => 10}, %{"item2" => "test"}, 10, 5.0, %{:NULL => true}],
            "null" => nil}
    encoded = {
      [{"M",
        [{"null", [{"NULL", true}]},
         {"key2", {[{"L", [
                        {[{"M", [{"item1", {[{"N", "10"}]}}]}]},
                        {[{"M", [{"item2", {[{"S", "test"}]}}]}]},
                        {[{"N", "10"}]},
                        {[{"N", "5.0"}]},
                        {[{"NULL", true}]}]}]}},
         {"key1", {[{"S", "value"}]}},
         {"binary", {[{"B", "dGVzdA=="}]}}]}]}
    assert encoded == Encoder.encode(map)
  end
  
end
