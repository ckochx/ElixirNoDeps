defmodule Mix.Tasks.RemotePresent do
  @moduledoc """
  Mix task to run presentations with remote control capabilities.

  Starts a presentation in the terminal for the audience while providing
  a web interface for remote control from a mobile device.

  ## Usage

      # Basic usage
      mix remote_present slides.md

      # With custom web port
      mix remote_present slides.md --port 3000

      # Run demo
      mix remote_present --demo

      # Run demo with custom port
      mix remote_present --demo --port 8080

  ## Options

    * `--port` - Web server port (default: 8080)
    * `--demo` - Run the built-in demo presentation
    * `--help` - Show this help

  ## Local Network Setup

  For conference use without WiFi:

  1. Create a hotspot on your laptop:
     - macOS: System Preferences > Sharing > Internet Sharing
     - Windows: Settings > Network > Mobile hotspot
     - Linux: Settings > WiFi > Use as Hotspot

  2. Connect your phone to the hotspot

  3. Run your presentation:
     ```
     mix remote_present slides.md
     ```

  4. Open the displayed URL on your phone for remote control
  """

  use Mix.Task

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

  @impl Mix.Task
  def run(args) do
    {opts, args, _} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    cond do
      opts[:help] ->
        show_help()

      opts[:demo] ->
        run_demo(opts)

      length(args) == 0 ->
        Mix.shell().error("Error: No presentation file specified.")
        Mix.shell().info("Use --demo to run a demo, or provide a markdown file.")
        Mix.shell().info("Run 'mix remote_present --help' for usage information.")

      true ->
        [file_path | _] = args
        run_presentation(file_path, opts)
    end
  end

  defp run_demo(opts) do
    web_port = opts[:port] || 8080

    Mix.shell().info("Starting remote control demo...")
    Mix.shell().info("Web server will start on port #{web_port}")

    # Start the application if not already started
    Mix.Task.run("app.start")

    RemotePresenter.demo(web_port: web_port)
  end

  defp run_presentation(file_path, opts) do
    web_port = opts[:port] || 8080

    # Check if file exists
    unless File.exists?(file_path) do
      Mix.shell().error("Error: File '#{file_path}' not found.")
      exit(:normal)
    end

    Mix.shell().info("Starting presentation: #{file_path}")
    Mix.shell().info("Web server will start on port #{web_port}")

    # Start the application if not already started
    Mix.Task.run("app.start")

    case RemotePresenter.run(file_path, web_port: web_port) do
      :ok ->
        Mix.shell().info("Presentation completed successfully.")

      {:error, reason} ->
        Mix.shell().error("Error: #{reason}")
        exit(:normal)
    end
  end

  defp show_help do
    Mix.shell().info("""
    mix remote_present - Run presentations with remote control

    USAGE:
        mix remote_present <file.md> [options]
        mix remote_present --demo [options]

    EXAMPLES:
        mix remote_present slides.md
        mix remote_present slides.md --port 3000
        mix remote_present --demo
        mix remote_present --demo --port 8080

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
           mix remote_present slides.md

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
