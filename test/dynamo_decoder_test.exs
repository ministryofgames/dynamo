defmodule DynamoDecoderTest do
  use ExUnit.Case
  doctest Dynamo.AttributeType.Decoder

  alias Dynamo.AttributeType.Decoder

  test "decode nil" do
    assert nil == Decoder.decode({[{"NULL", true}]})
  end

  test "decode boolean" do
    assert true == Decoder.decode({[{"BOOL", "true"}]})
    assert false == Decoder.decode({[{"BOOL", "false"}]})
  end

  test "decode string" do
    assert "string" == Decoder.decode({[{"S", "string"}]})
  end

  test "decode number" do
    assert 1.0 == Decoder.decode({[{"N", "1.0"}]})
    assert 1 == Decoder.decode({[{"N", "1"}]})
  end

  test "decode map" do
    map = Decoder.decode({[{"M", {[{"string", {[{"S", "string"}]}},
                                   {"number", {[{"N", "1.0"}]}}]}}]})
    assert map == %{"number" => 1.0, "string" => "string"}
  end

  test "decode list" do
    list = Decoder.decode({[{"L", [{[{"S", "string"}]}, {[{"N", "1.0"}]}]}]})
    assert list == ["string", 1.0]
  end
  
end
