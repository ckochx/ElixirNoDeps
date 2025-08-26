defmodule ElixirNoDeps.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Initialize poll storage ETS table
    ElixirNoDeps.PollStorage.start_link()

    children = [
      # Starts a worker by calling: ElixirNoDeps.Worker.start_link(arg)
      # {ElixirNoDeps.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirNoDeps.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
