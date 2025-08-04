defmodule ElixirNoDeps.HttpC do
  @moduledoc """
  HTTP client module using Erlang's httpc library.
  """

  @doc """
  Make an HTTP GET request to the given URL.
  
  ## Examples
  
      iex> ElixirNoDeps.HttpC.get("https://httpbin.org/get")
      {:ok, %{status: 200, headers: [...], body: "..."}}
      
      iex> ElixirNoDeps.HttpC.get("invalid-url")
      {:error, :nxdomain}
  """
  def get(url) when is_binary(url) do
    :inets.start()
    :ssl.start()
    
    http_options = build_http_options(url)
    
    case :httpc.request(:get, {String.to_charlist(url), []}, http_options, []) do
      {:ok, {{_version, status_code, _reason}, headers, body}} ->
        {:ok, %{
          status: status_code,
          headers: normalize_headers(headers),
          body: List.to_string(body)
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Make an HTTP POST request to the given URL with data.
  
  ## Examples
  
      iex> ElixirNoDeps.HttpC.post("https://httpbin.org/post", "data", [{"content-type", "text/plain"}])
      {:ok, %{status: 200, headers: [...], body: "..."}}
  """
  def post(url, data, headers \\ []) when is_binary(url) and is_binary(data) do
    :inets.start()
    :ssl.start()
    
    content_type = get_content_type(headers)
    request_headers = normalize_request_headers(headers)
    http_options = build_http_options(url)
    
    case :httpc.request(:post, {String.to_charlist(url), request_headers, content_type, String.to_charlist(data)}, http_options, []) do
      {:ok, {{_version, status_code, _reason}, response_headers, body}} ->
        {:ok, %{
          status: status_code,
          headers: normalize_headers(response_headers),
          body: List.to_string(body)
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Make an HTTP PUT request to the given URL with data.
  """
  def put(url, data, headers \\ []) when is_binary(url) and is_binary(data) do
    :inets.start()
    :ssl.start()
    
    content_type = get_content_type(headers)
    request_headers = normalize_request_headers(headers)
    http_options = build_http_options(url)
    
    case :httpc.request(:put, {String.to_charlist(url), request_headers, content_type, String.to_charlist(data)}, http_options, []) do
      {:ok, {{_version, status_code, _reason}, response_headers, body}} ->
        {:ok, %{
          status: status_code,
          headers: normalize_headers(response_headers),
          body: List.to_string(body)
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Make an HTTP DELETE request to the given URL.
  """
  def delete(url, headers \\ []) when is_binary(url) do
    :inets.start()
    :ssl.start()
    
    request_headers = normalize_request_headers(headers)
    http_options = build_http_options(url)
    
    case :httpc.request(:delete, {String.to_charlist(url), request_headers}, http_options, []) do
      {:ok, {{_version, status_code, _reason}, response_headers, body}} ->
        {:ok, %{
          status: status_code,
          headers: normalize_headers(response_headers),
          body: List.to_string(body)
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Make a generic HTTP request with custom method, headers, and body.
  """
  def request(method, url, headers \\ [], body \\ "") when is_atom(method) and is_binary(url) do
    :inets.start()
    
    case method do
      :get ->
        get(url)
      :post ->
        post(url, body, headers)
      :put ->
        put(url, body, headers)
      :delete ->
        delete(url, headers)
      _ ->
        {:error, :unsupported_method}
    end
  end

  # Private functions

  defp build_http_options(url) do
    base_options = [timeout: 30_000]
    
    if String.starts_with?(url, "https://") do
      base_options ++ [
        ssl: [
          verify: :verify_none,
          versions: [:"tlsv1.2", :"tlsv1.3"]
        ]
      ]
    else
      base_options
    end
  end

  defp normalize_headers(headers) do
    headers
    |> Enum.map(fn {key, value} ->
      {List.to_string(key), List.to_string(value)}
    end)
  end

  defp normalize_request_headers(headers) do
    headers
    |> Enum.map(fn {key, value} ->
      {String.to_charlist(key), String.to_charlist(value)}
    end)
  end

  defp get_content_type(headers) do
    case Enum.find(headers, fn {key, _value} -> String.downcase(key) == "content-type" end) do
      {_key, value} -> String.to_charlist(value)
      nil -> ~c(application/x-www-form-urlencoded)
    end
  end
end