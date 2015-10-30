defmodule DynamoTest do
  use ExUnit.Case

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "build result" do
    result = {[{"TableDescription",
                {[{"AttributeDefinitions",
                   [{[{"AttributeName", "test"}, {"AttributeType", "S"}]}]},
                  {"TableName", "test"},
                  {"KeySchema", [{[{"AttributeName", "test"}, {"KeyType", "HASH"}]}]},
                  {"TableStatus", "ACTIVE"}, {"CreationDateTime", 1446198629.408},
                  {"ProvisionedThroughput",
                   {[{"LastIncreaseDateTime", 0.0},
                     {"LastDecreaseDateTime", 0.0},
                     {"NumberOfDecreasesToday", 0},
                     {"ReadCapacityUnits", 1},
                     {"WriteCapacityUnits", 1}]}},
                  {"TableSizeBytes", 0}, {"ItemCount", 0},
                  {"TableArn", "arn:aws:dynamodb:ddblocal:000000000000:table/test"}]}}]}

    map = %{"TableDescription" =>
             %{"AttributeDefinitions" => [%{"AttributeName" => "test", "AttributeType" => "S"}],
               "CreationDateTime" => 1446198629.408,
               "ItemCount" => 0,
               "KeySchema" => [%{"AttributeName" => "test", "KeyType" => "HASH"}],
               "ProvisionedThroughput" => %{"LastDecreaseDateTime" => 0.0,
                                            "LastIncreaseDateTime" => 0.0,
                                            "NumberOfDecreasesToday" => 0,
                                            "ReadCapacityUnits" => 1,
                                            "WriteCapacityUnits" => 1},
               "TableArn" => "arn:aws:dynamodb:ddblocal:000000000000:table/test",
               "TableName" => "test", "TableSizeBytes" => 0, "TableStatus" => "ACTIVE"}}
    
    assert map == Dynamo.build_result(result)
  end
  
end
