defmodule ElixirNoDeps.RemotePresenter.CLI do
  @moduledoc """
  CLI interface for the remote_present escript.
  
  This module provides the main entry point for the remote_present binary,
  offering the same functionality as the Mix.Tasks.RemotePresent task.
  """

  alias ElixirNoDeps.RemotePresenter

  @switches [
    port: :integer,
    demo: :boolean,
    help: :boolean
  ]

  @aliases [
    p: :port,
    d: :demo,
    h: :help
  ]

  def main(args) do
    {opts, args, _} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    # Start the application
    start_application()

    cond do
      opts[:help] ->
        show_help()

      opts[:demo] ->
        run_demo(opts)

      length(args) == 0 ->
        IO.puts(:stderr, "Error: No presentation file specified.")
        IO.puts("Use --demo to run a demo, or provide a markdown file.")
        IO.puts("Run 'remote_present --help' for usage information.")
        System.halt(1)

      true ->
        [file_path | _] = args
        run_presentation(file_path, opts)
    end
  end

  defp start_application do
    Application.ensure_all_started(:elixir_no_deps)
  end

  defp run_demo(opts) do
    web_port = opts[:port] || 8080

    IO.puts("Starting remote control demo...")
    IO.puts("Web server will start on port #{web_port}")

    RemotePresenter.demo(web_port: web_port)
  end

  defp run_presentation(file_path, opts) do
    web_port = opts[:port] || 8080

    # Check if file exists
    unless File.exists?(file_path) do
      IO.puts(:stderr, "Error: File '#{file_path}' not found.")
      System.halt(1)
    end

    IO.puts("Starting presentation: #{file_path}")
    IO.puts("Web server will start on port #{web_port}")

    case RemotePresenter.run(file_path, web_port: web_port) do
      :ok ->
        IO.puts("Presentation completed successfully.")

      {:error, reason} ->
        IO.puts(:stderr, "Error: #{reason}")
        System.halt(1)
    end
  end

  defp show_help do
    IO.puts("""
    remote_present - Run presentations with remote control

    USAGE:
        remote_present <file.md> [options]
        remote_present --demo [options]

    EXAMPLES:
        remote_present slides.md
        remote_present slides.md --port 3000
        remote_present --demo
        remote_present --demo --port 8080

    OPTIONS:
        --port, -p      Web server port (default: 8080)
        --demo, -d      Run the built-in demo presentation
        --help, -h      Show this help message

    CONFERENCE SETUP (No WiFi Required):

        1. Create laptop hotspot:
           • macOS: System Preferences > Sharing > Internet Sharing
           • Windows: Settings > Network > Mobile hotspot
           • Linux: Settings > WiFi > Use as Hotspot

        2. Connect phone to laptop's hotspot

        3. Run presentation:
           remote_present slides.md

        4. Open the URL displayed on your phone

        5. Control presentation remotely while audience sees terminal

    FEATURES:
        ✅ Speaker notes visible only on phone
        ✅ Real-time slide synchronization
        ✅ Mobile-friendly interface
        ✅ No internet connection required
        ✅ Works with any markdown presentation

    For more information, visit: https://github.com/your-repo/ElixirNoDeps
    """)
  end
end