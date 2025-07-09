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
      # no deps
      # deps: deps()
    ]
  end


  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssh],
      mod: []
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssh],
      mod: {ElixirNoDeps.Application, []}
    ]
  end
end
