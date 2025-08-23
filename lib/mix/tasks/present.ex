defmodule Mix.Tasks.Present do
  @moduledoc """
  Mix task for running terminal presentations.

  ## Usage

      # Run a presentation from a markdown file
      mix present slides.md

      # Run with options
      mix present slides.md --theme dark --author "Your Name"

      # Run the built-in demo
      mix present --demo

  ## Options

    * `--demo` - Run the built-in demo presentation
    * `--theme` - Set the presentation theme (default: "default")
    * `--author` - Override the presentation author
    * `--title` - Override the presentation title

  ## Examples

      mix present README.md
      mix present --demo
      mix present slides.md --theme dark
  """

  use Mix.Task

  @shortdoc "Run a terminal-based presentation"

  @impl Mix.Task
  def run(args) do
    {opts, files, _invalid} = OptionParser.parse(args,
      switches: [
        demo: :boolean,
        theme: :string,
        author: :string,
        title: :string,
        help: :boolean
      ],
      aliases: [
        d: :demo,
        t: :theme,
        a: :author,
        h: :help
      ]
    )

    cond do
      opts[:help] ->
        show_help()

      opts[:demo] ->
        run_demo()

      length(files) == 1 ->
        run_presentation(List.first(files), opts)

      length(files) == 0 ->
        Mix.shell().error("No presentation file specified. Use --demo for a demo or specify a markdown file.")
        show_usage()

      true ->
        Mix.shell().error("Too many files specified. Please specify only one presentation file.")
        show_usage()
    end
  end

  defp run_demo do
    Mix.shell().info("Starting demo presentation...")
    
    # Ensure the application is started
    Application.ensure_all_started(:elixir_no_deps)
    
    case ElixirNoDeps.Presenter.demo() do
      :ok ->
        Mix.shell().info("Demo completed successfully!")
      {:error, reason} ->
        Mix.shell().error("Demo failed: #{reason}")
        System.halt(1)
    end
  end

  defp run_presentation(file_path, opts) do
    unless File.exists?(file_path) do
      Mix.shell().error("File not found: #{file_path}")
      System.halt(1)
    end

    Mix.shell().info("Loading presentation: #{file_path}")
    
    # Ensure the application is started
    Application.ensure_all_started(:elixir_no_deps)
    
    # Filter and prepare options
    presenter_opts = opts
                     |> Enum.filter(fn {key, _} -> key in [:theme, :author, :title] end)
                     |> Enum.reject(fn {_, value} -> is_nil(value) end)

    case ElixirNoDeps.Presenter.run(file_path, presenter_opts) do
      :ok ->
        Mix.shell().info("Presentation completed successfully!")
      {:error, reason} ->
        Mix.shell().error("Presentation failed: #{reason}")
        System.halt(1)
    end
  end

  defp show_help do
    Mix.shell().info(@moduledoc)
  end

  defp show_usage do
    Mix.shell().info("""
    Usage:
      mix present <file.md>        Run presentation from markdown file
      mix present --demo           Run built-in demo
      mix present --help           Show detailed help

    Examples:
      mix present slides.md
      mix present --demo
      mix present presentation.md --theme dark
    """)
  end
end