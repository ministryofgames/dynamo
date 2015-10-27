defmodule Dynamo.Auth.Utils do
  
  def hmac_sha256(key, data), do: :crypto.hmac(:sha256, key, data)
  def sha256(data),           do: :crypto.hash(:sha256, data)

  def hexdigest(data) do
    :io_lib.format('~64.16.0b', [:binary.decode_unsigned(data)])
    |> List.to_string
  end

  def iso_8601_date() do
    {{year, month, day}, {hour, min, sec}} =
      :calendar.now_to_universal_time(:os.timestamp())
    
    List.to_string(:lists.flatten(:io_lib.format(
              '~4.10.0B~2.10.0B~2.10.0BT~2.10.0B~2.10.0B~2.10.0BZ',
              [year, month, day, hour, min, sec])))
  end

end

defmodule Dynamo.Auth.Signature.V4 do

  import Dynamo.Auth.Utils

  def sign(request, region) do
    # we only use dynamodb
    service = "dynamodb"
    
    {key, secret} = IamRole.get_credentials
    
    # set datetime for the request
    {_, datetime} = List.keyfind(
      request.headers, "x-amz-date", 0, {"x-amz-date", iso_8601_date()})
    
    [date, _] = String.split(datetime, "T")
    
    # create the signing key
    signing_key = hmac_sha256("AWS4" <> secret, date)
    |> hmac_sha256(region)
    |> hmac_sha256(service)
    |> hmac_sha256("aws4_request")

    # update the request headers
    headers = request.headers
    |> List.keystore(
      "x-amz-date", 0, {"x-amz-date", datetime})
    |> List.keystore(
      "x-amz-content-sha256", 0,
      {"x-amz-content-sha256", sha256(request.payload) |> hexdigest})
    request = %{request | :headers => headers}

    # create the signature
    {signed_headers, cr_string} = canonical_request(request)
    string_to_sign = string_to_sign(region, service,
                                    datetime, date, cr_string)
    signature = signing_key
    |> hmac_sha256(string_to_sign)
    |> hexdigest
      
    credential_scope = "#{date}/#{region}/#{service}/aws4_request"
    auth_header = "AWS4-HMAC-SHA256 Credential=#{key}/#{credential_scope}, " <>
      "SignedHeaders=#{signed_headers}, Signature=#{signature}"
    
    %{request | :headers => [{"Authorization", auth_header} | request.headers]}
  end
  
  defp string_to_sign(region, service, datetime, date, canonical_request) do
    hash = sha256(canonical_request)
    |> hexdigest
    "AWS4-HMAC-SHA256\n#{datetime}\n#{date}/#{region}/#{service}/aws4_request\n#{hash}"
  end

  defp canonical_request(request) do
    {signed_headers, canonical_headers} = canonical_headers(request.headers)
    payload = sha256(request.payload)
    |> hexdigest
    method = request.method |> to_string |> String.upcase
    canonical_string = "#{method}\n#{request.uri.path}\n#{request.uri.query}\n" <>
      "#{canonical_headers}\n#{signed_headers}\n#{payload}"
    {signed_headers, canonical_string}
  end
  
  defp canonical_headers(headers) do
    {signed_headers, canonical_headers} = Enum.map(headers,
      fn {header, value} ->
        {String.downcase(header), String.strip(value)}
      end)
    |> Enum.sort
    |> Enum.map_reduce("",
      fn ({header, value}, acc) ->
        {header, acc <> "#{header}:#{value}\n"}
      end)
    {Enum.join(signed_headers, ";"), canonical_headers}
  end  

end
