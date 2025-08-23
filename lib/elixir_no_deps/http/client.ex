defmodule ElixirNoDeps.HTTP.Client do
  @moduledoc """
  A simple HTTP client that uses Erlang's :httpc module to retrieve web pages.
  """

  @doc """
  Retrieves a web page from the given URL.

  ## Parameters
  - `url`: The URL to fetch (string)
  - `options`: Optional keyword list of options

  ## Options
  - `:timeout`: Request timeout in milliseconds (default: 5000)
  - `:headers`: List of headers as tuples (default: [])
  - `:follow_redirect`: Whether to follow redirects (default: true)

  ## Returns
  - `{:ok, {status_code, headers, body}}` on success
  - `{:error, reason}` on failure

  ## Examples

      iex> HttpClient.get("https://httpbin.org/get")
      {:ok, {200, [...], "..."}}

      iex> HttpClient.get("https://httpbin.org/status/404")
      {:ok, {404, [...], "..."}}

      iex> HttpClient.get("invalid-url")
      {:error, :invalid_url}
  """
  def get(url, options \\ []) do
    # Start inets application if not already started
    :inets.start()

    # Parse options
    timeout = Keyword.get(options, :timeout, 5000)
    headers = Keyword.get(options, :headers, [])
    follow_redirect = Keyword.get(options, :follow_redirect, true)

    # Convert headers to the format expected by httpc
    httpc_headers =
      Enum.map(headers, fn {key, value} ->
        {to_charlist(key), to_charlist(value)}
      end)

    # Set up httpc options
    httpc_options = [
      timeout: timeout,
      autoredirect: follow_redirect
    ]

    # Convert URL to charlist as required by httpc
    char_url = to_charlist(url)

    # Make the HTTP request
    case :httpc.request(:get, {char_url, httpc_headers}, httpc_options, []) do
      {:ok, {{_http_version, status_code, _reason_phrase}, response_headers, body}} ->
        # Convert response headers back to strings
        parsed_headers =
          Enum.map(response_headers, fn {key, value} ->
            {to_string(key), to_string(value)}
          end)

        {:ok, {status_code, parsed_headers, to_string(body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Retrieves a web page and returns only the body on success.

  ## Parameters
  - `url`: The URL to fetch (string)
  - `options`: Optional keyword list of options (same as get/2)

  ## Returns
  - `{:ok, body}` on success
  - `{:error, reason}` on failure

  ## Examples

      iex> HttpClient.get_body("https://httpbin.org/get")
      {:ok, "..."}
  """
  def get_body(url, options \\ []) do
    case get(url, options) do
      {:ok, {_status_code, _headers, body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Makes an HTTP request with the specified method.

  ## Parameters
  - `method`: HTTP method as atom (:get, :post, :put, :delete, etc.)
  - `url`: The URL to fetch (string)
  - `body`: Request body (string, default: "")
  - `options`: Optional keyword list of options

  ## Options
  Same as get/2, plus:
  - `:content_type`: Content-Type header for the request body

  ## Returns
  - `{:ok, {status_code, headers, body}}` on success
  - `{:error, reason}` on failure

  ## Examples

      iex> HttpClient.request(:post, "https://httpbin.org/post", "{\"key\": \"value\"}",
      ...>   content_type: "application/json")
      {:ok, {200, [...], "..."}}
  """
  def request(method, url, body \\ "", options \\ []) do
    # Start inets application if not already started
    :inets.start()

    # Parse options
    timeout = Keyword.get(options, :timeout, 5000)
    headers = Keyword.get(options, :headers, [])
    content_type = Keyword.get(options, :content_type, "application/octet-stream")
    follow_redirect = Keyword.get(options, :follow_redirect, true)

    # Convert headers to the format expected by httpc
    httpc_headers =
      Enum.map(headers, fn {key, value} ->
        {to_charlist(key), to_charlist(value)}
      end)

    # Set up httpc options
    httpc_options = [
      timeout: timeout,
      autoredirect: follow_redirect
    ]

    # Convert parameters to charlists as required by httpc
    char_url = to_charlist(url)
    char_content_type = to_charlist(content_type)
    char_body = to_charlist(body)

    # Build the request tuple based on whether we have a body
    request_tuple =
      if body != "" do
        {char_url, httpc_headers, char_content_type, char_body}
      else
        {char_url, httpc_headers}
      end

    # Make the HTTP request
    case :httpc.request(method, request_tuple, httpc_options, []) do
      {:ok, {{_http_version, status_code, _reason_phrase}, response_headers, response_body}} ->
        # Convert response headers back to strings
        parsed_headers =
          Enum.map(response_headers, fn {key, value} ->
            {to_string(key), to_string(value)}
          end)

        {:ok, {status_code, parsed_headers, to_string(response_body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
