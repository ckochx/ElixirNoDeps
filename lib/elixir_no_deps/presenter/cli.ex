defmodule ElixirNoDeps.Presenter.CLI do
  @moduledoc """
  Command-line interface for the ElixirNoDeps Presenter.

  This module serves as the main entry point for the escript version,
  providing true raw keyboard input capabilities outside of Mix.
  """

  alias ElixirNoDeps.Presenter

  @doc """
  Main entry point for the escript.
  """
  def main(args) do
    # Set up proper shutdown handling
    Process.flag(:trap_exit, true)

    case parse_args(args) do
      {:ok, file_path, opts} ->
        # Ensure applications are started
        Application.ensure_all_started(:elixir_no_deps)

        # Show startup message
        IO.puts("🚀 ElixirNoDeps Presenter (escript version)")
        IO.puts("📁 Loading: #{file_path}")
        IO.puts("")

        # Run the presentation
        case Presenter.run(file_path, opts) do
          :ok ->
            System.halt(0)

          {:error, reason} ->
            IO.puts("❌ Error: #{reason}")
            System.halt(1)
        end

      {:error, :help} ->
        print_help()
        System.halt(0)

      {:error, reason} ->
        IO.puts("❌ #{reason}")
        print_usage()
        System.halt(1)
    end
  end

  # Private functions

  defp parse_args([]) do
    {:error, "No presentation file specified"}
  end

  defp parse_args(["--help" | _]) do
    {:error, :help}
  end

  defp parse_args(["-h" | _]) do
    {:error, :help}
  end

  defp parse_args([file_path | rest]) do
    # Check if file exists
    if File.exists?(file_path) do
      opts = parse_options(rest, [])
      {:ok, file_path, opts}
    else
      {:error, "File not found: #{file_path}"}
    end
  end

  defp parse_options([], acc), do: Enum.reverse(acc)

  defp parse_options(["--theme", theme | rest], acc) do
    parse_options(rest, [{:theme, theme} | acc])
  end

  defp parse_options(["--author", author | rest], acc) do
    parse_options(rest, [{:author, author} | acc])
  end

  defp parse_options(["--title", title | rest], acc) do
    parse_options(rest, [{:title, title} | acc])
  end

  defp parse_options([unknown | rest], acc) do
    IO.puts("⚠️  Warning: Unknown option #{unknown}")
    parse_options(rest, acc)
  end

  defp print_help do
    IO.puts("""
    🎯 ElixirNoDeps Presenter - Terminal-based presentations in Elixir

    USAGE:
        present <file.md> [options]

    ARGUMENTS:
        <file.md>           Markdown presentation file

    OPTIONS:
        --theme <theme>     Set presentation theme
        --author <author>   Override author name
        --title <title>     Override presentation title
        --help, -h          Show this help message

    NAVIGATION:
        Enter                      Next slide
        p + Enter                  Previous slide
        0 + Enter                  First slide
        $ + Enter                  Last slide
        1-9 + Enter                Jump to slide number
        r + Enter                  Refresh/redraw
        ? + Enter                  Show help
        q + Enter                  Quit presentation

    FEATURES:
        ✅ Simple Enter-based navigation
        ✅ ANSI colors and formatting
        ✅ ASCII art integration
        ✅ Markdown support with frontmatter
        ✅ Works in all terminal environments

    EXAMPLES:
        present slides.md
        present presentation.md --theme dark --author "Your Name"

    NOTE: All navigation requires pressing Enter after the key. This ensures
    reliable operation across all terminal environments.
    """)
  end

  defp print_usage do
    IO.puts("""
    Usage: present <file.md> [options]

    Try 'present --help' for more information.
    """)
  end
end
