defmodule ElixirNoDeps.RemotePresenter do
  @moduledoc """
  Enhanced presenter that supports remote control via web interface.

  Runs the normal terminal presentation for the audience while providing
  a web interface for the presenter to control slides and view speaker notes
  from a mobile device.
  """

  alias ElixirNoDeps.Presenter
  alias ElixirNoDeps.Presenter.Parser
  alias ElixirNoDeps.WebRemoteServer

  @doc """
  Runs a presentation with remote control capabilities.

  This starts both:
  1. The terminal presentation (for the audience)
  2. A web server for remote control (for the presenter)

  ## Examples

      # Basic usage
      ElixirNoDeps.RemotePresenter.run("slides.md")

      # With custom port
      ElixirNoDeps.RemotePresenter.run("slides.md", web_port: 8080)

      # With presentation options
      ElixirNoDeps.RemotePresenter.run("slides.md", theme: "dark", web_port: 3000)
  """
  @spec run(String.t(), keyword()) :: :ok | {:error, String.t()}
  def run(file_path, opts \\ []) do
    web_port = Keyword.get(opts, :web_port, 8080)
    presentation_opts = Keyword.drop(opts, [:web_port])

    # Start the web server in a separate process
    web_server_pid =
      spawn_link(fn ->
        WebRemoteServer.start(web_port)
      end)

    # Give the web server a moment to start
    Process.sleep(500)

    # Create enhanced presentation with connection slide
    case create_presentation_with_connection_slide(file_path, web_port, presentation_opts) do
      {:ok, enhanced_presentation} ->
        # Run the enhanced presentation
        result = Presenter.run_presentation(enhanced_presentation)

        # Clean up web server when presentation ends
        if Process.alive?(web_server_pid) do
          Process.exit(web_server_pid, :kill)
        end

        result

      {:error, reason} ->
        # Clean up web server on error
        if Process.alive?(web_server_pid) do
          Process.exit(web_server_pid, :kill)
        end

        {:error, reason}
    end
  end

  @doc """
  Runs a presentation from a Presentation struct with remote control.
  """
  @spec run_presentation(ElixirNoDeps.Presenter.Presentation.t(), keyword()) :: :ok
  def run_presentation(presentation, opts \\ []) do
    web_port = Keyword.get(opts, :web_port, 8080)

    # Start the web server in a separate process
    web_server_pid =
      spawn_link(fn ->
        WebRemoteServer.start(web_port)
      end)

    # Give the web server a moment to start
    Process.sleep(500)

    # Run the presentation normally
    result = Presenter.run_presentation(presentation)

    # Clean up web server when presentation ends
    if Process.alive?(web_server_pid) do
      Process.exit(web_server_pid, :kill)
    end

    result
  end

  @doc """
  Creates a demo presentation with remote control capabilities.
  """
  @spec demo(keyword()) :: :ok
  def demo(opts \\ []) do
    demo_content = """
    ---
    title: "Remote Control Demo"
    author: "ElixirNoDeps Presenter"
    theme: "default"
    ---

    # Welcome to Remote Control! 📱

    This presentation is being controlled remotely.

    The **audience** sees this in the terminal.
    The **presenter** controls it from their phone!

    <!-- Speaker notes: Welcome everyone! Explain that you're controlling this from your phone. The audience can't see these notes. -->

    ---

    # How It Works

    ## For the Audience 👥
    - Clean terminal presentation
    - No distractions
    - Professional appearance

    ## For the Presenter 📱
    - Mobile web interface
    - **Speaker notes** (like this one!)
    - Slide navigation controls
    - Current slide preview

    <!-- Speaker notes: Point out that you can see these notes on your phone but the audience cannot. This is perfect for conference presentations where WiFi might be unreliable. -->

    ---

    # Features

    ✅ **No WiFi required** - runs on local network
    ✅ **Speaker notes** - visible only to presenter
    ✅ **Mobile friendly** - works on any phone/tablet
    ✅ **Real-time sync** - terminal updates instantly
    ✅ **Clean separation** - audience sees clean slides

    Navigate with your phone to test it out!

    <!-- Speaker notes: Try navigating back and forth to show how responsive it is. The audience will see the slides change in real-time while you control from your phone. -->

    ---

    # Perfect for Conferences 🎯

    ## The Problem
    - Conference WiFi is unreliable
    - Need to move around while presenting
    - Want to see speaker notes privately

    ## The Solution
    - Create local hotspot on laptop
    - Connect phone to local network
    - Control presentation remotely
    - **No internet required!**

    <!-- Speaker notes: This solves the classic conference problem of unreliable WiFi. You create your own network between your laptop and phone. -->

    ---

    # Getting Started

    ```elixir
    # Start with remote control
    ElixirNoDeps.RemotePresenter.run("slides.md")

    # Custom port
    ElixirNoDeps.RemotePresenter.run("slides.md", web_port: 3000)
    ```

    Then connect your phone to the displayed URL!

    <!-- Speaker notes: Show the audience how simple the API is. The URL will be displayed when you start the presentation. -->

    ---

    # Thank You!

    ## Questions?

    Try controlling this presentation from your phone:
    - Open the URL shown when you started
    - Navigate through slides
    - See these speaker notes that audience can't see

    **Built with Elixir 💜 - No external dependencies!**

    <!-- Speaker notes: Thank the audience and encourage them to try it out. Emphasize that this entire system was built without any external dependencies, staying true to the ElixirNoDeps philosophy. -->
    """

    # Write temporary demo file
    demo_file = "/tmp/elixir_remote_presenter_demo.md"
    File.write!(demo_file, demo_content)

    # Run the demo with remote control
    result = run(demo_file, opts)

    # Cleanup
    File.rm(demo_file)

    result
  end

  # Private helper functions

  defp create_presentation_with_connection_slide(file_path, web_port, _presentation_opts) do
    case Parser.parse_file(file_path) do
      {:ok, original_presentation} ->
        # Create connection slide content
        connection_slide_content = create_connection_slide_content(web_port)

        # Parse the connection slide
        connection_presentation = Parser.parse_content(connection_slide_content)
        connection_slide = List.first(connection_presentation.slides)

        # Combine connection slide with original slides
        enhanced_slides = [connection_slide | original_presentation.slides]

        # Create enhanced presentation with metadata from original
        enhanced_presentation = %{
          original_presentation
          | slides: enhanced_slides,
            # Start on connection slide
            current_slide: 0
        }

        {:ok, enhanced_presentation}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_connection_slide_content(_web_port) do
    """
    # 📱 Scan to Connect!

    ![QR Code](priv/assets/qr_code.png)

    ## For Audience
    **Scan the QR code above to follow along with the presentation**

    ## Ready to Start?
    **Press Enter** to begin the presentation

    <!-- Speaker notes: Test the connection now! Go to the URL on your phone, choose Presenter, and enter your password. The audience can scan the QR code to follow along! -->

    ---
    """
  end
end
