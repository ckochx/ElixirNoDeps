defmodule ElixirNoDeps.SSH.Tunnel do
  @moduledoc """
  Connect through the a remote host and tunnel this connection to a localhost port (9000 by default)
  In this implementation, the remote host is the an SSH bastion.

  This module implements the necessary steps needed to make a remote connection available at `localhost:9000`
  """

  @behaviour :ssh_client_key_api

  defmodule ConnectionError do
    defexception [:message]
  end

  require Logger

  def connect do
    :username
    |> config()
    |> start()
    |> port_forward!()
  end

  def start(user) do
    remote_host = config(:hostname)

    ssh_key =
      config(:ssh_key) || File.read!(Path.join([System.user_home(), ".ssh", "id_ed25519"]))

    case :ssh.connect(String.to_charlist(remote_host), 22,
           auth_methods: ~c"publickey",
           key_cb: {__MODULE__, user_key: ssh_key},
           silently_accept_hosts: true,
           user: String.to_charlist(user),
           user_interaction: false
         ) do
      {:ok, conn_pid} ->
        Logger.debug("Successfully connected to #{remote_host}")
        conn_pid

      {:error, reason} ->
        Logger.error("Failed to connect: #{inspect(reason)}")
        raise ConnectionError, message: "#{reason}"
    end
  end

  @spec stop(pid()) :: :ok | {:error, term()}
  def stop(conn) do
    :ssh.close(conn)
  end

  @doc """
  Given a ref/pid to an open SSH connection; configure a tunnel to bind a local port in config
  to a port: remote_port on the remote host.
  """
  def port_forward!(conn) when is_pid(conn) do
    local_port = config(:local_port)
    remote_port = config(:remote_port)

    case :ssh.tcpip_tunnel_to_server(conn, :loopback, local_port, :loopback, remote_port) do
      {:ok, ^local_port} ->
        Logger.debug(
          "Port forwarding from local port #{local_port} to remote port #{remote_port}"
        )

      {:error, :eaddrinuse} ->
        Logger.debug(
          "Port forwarding from local port #{local_port} to remote port #{remote_port} already in place"
        )

      error ->
        Logger.error(inspect(error))
        raise ConnectionError, message: error
    end

    conn
  end

  @doc "this is a required but indirectly used callback"
  @impl :ssh_client_key_api
  def add_host_key(_hostnames, _key, _connect_opts) do
    :ok
  end

  @doc "this is a required but indirectly used callback"
  @impl :ssh_client_key_api
  def is_host_key(_key, _host, _algorithm, _connect_opts) do
    true
  end

  @doc """
  This erlang :ssh callback handles decoding a String SSH key into the "correct" binary that :ssh needs for the identity file.
  Most of the failure modes in this code are silent by design.
  If you are unable to authenticate, it may be the case that there is a copy-paste or escape char
  error in the ssh_key value.
  """
  @impl :ssh_client_key_api
  def user_key(_algorithm, opts) do
    data = opts[:key_cb_private][:user_key]

    case :ssh_file.decode(data, :public_key) do
      [{key, _comments} | _rest] ->
        {:ok, key}

      {:error, :key_decode_failed} ->
        Logger.error("key_decode_failed")
        {:error, :key_decode_failed}

      other ->
        Logger.error("Unexpected return value from :ssh_file.decode/2 #{inspect(other)}")
        {:error, :ssh_client_key_api_unable_to_decode_key}
    end
  end

  defp config(key) do
    Application.get_env(:elixir_no_deps, key)
  end
end
