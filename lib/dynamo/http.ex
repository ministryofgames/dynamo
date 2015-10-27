defmodule Dynamo.Http do

  @api_version "DynamoDB_20120810"

  alias Dynamo.Auth.Signature
  
  defmodule Request do
    defstruct method: nil, headers: [], uri: nil, payload: ""
  end

  defmodule Response do
    defstruct status_code: nil, headers: [], payload: ""
  end

  def post(opname, payload \\ "") do
    region = Application.get_env(:dynamo, :region, "us-east-1")
    uri = get_uri(region) |> URI.parse
    
    headers = [{"host", uri.host},
               {"x-amz-target", "#{@api_version}.#{opname}"},
               {"content-type", "application/x-amz-json-1.0"}]
    
    request = %Request{method: :post, headers: headers, uri: uri, payload: payload}
    |> Signature.V4.sign(region)
    
    {:ok, status_code, response_headers, client_ref} =
      :hackney.request(request.method, URI.to_string(request.uri),
                       request.headers, request.payload, [])
    {:ok, response_payload} = :hackney.body(client_ref)
    
    case List.keyfind(response_headers, "Content-Type", 0) do
      {"Content-Type", "application/x-amz-json-1.0"} ->
        response_payload = :jsone.decode(response_payload)
      nil ->
        :ok
    end
    
    %Response{status_code: status_code, headers: response_headers,
              payload: response_payload}
  end
  
  defp get_uri("local"), do: "http://localhost:8000/"
  defp get_uri(region), do: "https://dynamodb.#{region}.amazonaws.com/"
  
end
