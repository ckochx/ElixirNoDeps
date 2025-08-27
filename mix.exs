defmodule ElixirNoDeps.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_no_deps,
      config_path: "config/config.exs",
      # elixirc_paths: elixirc_paths(Mix.env()),
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      escript: escript_config()
      # no deps
      # deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssh, :inets, :ssl],
      mod: {ElixirNoDeps.Application, []}
    ]
  end

  defp escript_config do
    case System.get_env("MIX_ESCRIPT_NAME") do
      "remote_present" ->
        [
          main_module: ElixirNoDeps.RemotePresenter.CLI,
          name: "remote_present"
        ]
      _ ->
        [
          main_module: ElixirNoDeps.Presenter.CLI,
          name: "present"
        ]
    end
  end
end
