defmodule ElixirNoDeps.SimpleHttpServer do
  @moduledoc """
  A minimal HTTP server using only core Erlang/Elixir modules.
  """

  def start(port \\ 8080) do
    {:ok, listen_socket} = :gen_tcp.listen(port, [
      :binary,
      packet: :raw,
      active: false,
      reuseaddr: true
    ])

    IO.puts("Server listening on port #{port}")
    accept_loop(listen_socket)
  end

  defp accept_loop(listen_socket) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)
    
    # Handle request in a separate process
    spawn(fn -> handle_request(client_socket) end)
    
    accept_loop(listen_socket)
  end

  defp handle_request(client_socket) do
    case :gen_tcp.recv(client_socket, 0) do
      {:ok, request} ->
        response = build_response(request)
        :gen_tcp.send(client_socket, response)
        :gen_tcp.close(client_socket)
      
      {:error, _reason} ->
        :gen_tcp.close(client_socket)
    end
  end

  defp build_response(request) do
    # Parse first line to get method and path
    [first_line | _] = String.split(request, "\r\n")
    [method, path, _version] = String.split(first_line, " ")

    body = """
    <html>
    <body>
    <h1>Hello from Elixir!</h1>
    <p>Method: #{method}</p>
    <p>Path: #{path}</p>
    <p>Time: #{DateTime.utc_now()}</p>
    </body>
    </html>
    """

    content_length = byte_size(body)

    """
    HTTP/1.1 200 OK\r
    Content-Type: text/html\r
    Content-Length: #{content_length}\r
    Connection: close\r
    \r
    #{body}
    """
  end
end