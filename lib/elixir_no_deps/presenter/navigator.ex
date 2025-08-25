defmodule ElixirNoDeps.Presenter.Navigator do
  @moduledoc """
  Handles keyboard navigation and input processing for presentations.

  Manages:
  - Keyboard input capture and processing
  - Navigation commands (next, prev, goto, quit)
  - Presentation state updates
  - Input validation and error handling
  """

  use GenServer

  alias ElixirNoDeps.Presenter.Input
  alias ElixirNoDeps.Presenter.Presentation
  alias ElixirNoDeps.Presenter.Renderer
  alias ElixirNoDeps.Presenter.Terminal

  @doc """
  Starts the navigator GenServer.
  """
  @spec start_link(Presentation.t()) :: GenServer.on_start()
  def start_link(%Presentation{} = presentation) do
    GenServer.start_link(__MODULE__, presentation, name: __MODULE__)
  end

  @doc """
  Starts the presentation navigation loop.
  """
  @spec run(Presentation.t()) :: :ok
  def run(%Presentation{} = presentation) do
    case start_link(presentation) do
      {:ok, _pid} ->
        render_current_slide()
        navigation_loop()

      {:error, reason} ->
        IO.puts("Failed to start navigator: #{inspect(reason)}")
        :error
    end
  end

  @doc """
  Renders the current slide.
  """
  @spec render_current_slide() :: :ok
  def render_current_slide do
    GenServer.cast(__MODULE__, :render_slide)
  end

  @doc """
  Processes a navigation command.
  """
  @spec navigate(atom()) :: :ok | :quit
  def navigate(command) do
    GenServer.call(__MODULE__, {:navigate, command})
  end

  @doc """
  Gets the current presentation state.
  """
  @spec get_presentation() :: Presentation.t()
  def get_presentation do
    GenServer.call(__MODULE__, :get_presentation)
  end

  @doc """
  Simulates a key press for remote control.
  """
  @spec simulate_key_press(String.t()) :: :ok | :quit
  def simulate_key_press(key) do
    command =
      case key do
        "enter" -> :next_slide
        # space bar
        " " -> :next_slide
        "p" -> :prev_slide
        "q" -> :quit
        _ -> :unknown
      end

    navigate(command)
  end

  # GenServer callbacks

  @impl true
  def init(%Presentation{} = presentation) do
    # Configure terminal for raw input mode
    configure_terminal()
    {:ok, presentation}
  end

  @impl true
  def handle_call({:navigate, command}, _from, presentation) do
    case process_navigation_command(command, presentation) do
      {:ok, new_presentation} ->
        # Re-render the terminal when navigation succeeds (for web remote control)
        Renderer.render_slide(new_presentation)
        {:reply, :ok, new_presentation}

      {:quit} ->
        {:stop, :normal, :quit, presentation}

      {:error, _reason} ->
        {:reply, :error, presentation}
    end
  end

  @impl true
  def handle_call(:get_presentation, _from, presentation) do
    {:reply, presentation, presentation}
  end

  @impl true
  def handle_cast(:render_slide, presentation) do
    Renderer.render_slide(presentation)
    {:noreply, presentation}
  end

  @impl true
  def terminate(_reason, _presentation) do
    restore_terminal()
    :ok
  end

  # Handle process crash/exit gracefully
  @impl true
  def handle_info({:EXIT, _pid, _reason}, presentation) do
    restore_terminal()
    {:noreply, presentation}
  end

  @impl true
  def handle_info(_msg, presentation) do
    {:noreply, presentation}
  end

  # Private functions

  defp navigation_loop do
    # Try raw input first, fallback to regular input if raw mode failed
    case get_input() do
      :quit ->
        :ok

      command ->
        case navigate(command) do
          :quit ->
            :ok

          :ok ->
            render_current_slide()
            navigation_loop()

          :error ->
            navigation_loop()
        end
    end
  end

  # Unified input method that adapts to the runtime environment
  defp get_input do
    case Input.get_input() do
      # Quit commands
      "q" ->
        :quit

      "Q" ->
        :quit

      :quit ->
        :quit

      # Next slide commands
      # Spacebar (primary)
      " " ->
        :next_slide

      # n key
      "n" ->
        :next_slide

      # vim down
      "j" ->
        :next_slide

      # Right arrow
      :arrow_right ->
        :next_slide

      # Down arrow
      :arrow_down ->
        :next_slide

      # Enter key
      :enter ->
        :next_slide

      # Previous slide commands
      # p key
      "p" ->
        :prev_slide

      # vim up
      "k" ->
        :prev_slide

      # vim left
      "h" ->
        :prev_slide

      # Left arrow
      :arrow_left ->
        :prev_slide

      # Up arrow
      :arrow_up ->
        :prev_slide

      # Backspace
      "\x7F" ->
        :prev_slide

      # Alt backspace
      "\x08" ->
        :prev_slide

      # Navigation shortcuts
      # Go to first slide
      "0" ->
        :first_slide

      # Go to last slide
      "$" ->
        :last_slide

      # Utility commands
      # Refresh/redraw
      "r" ->
        :refresh

      # Show help
      "?" ->
        :help

      # Alternative help
      "/" ->
        :help

      # Handle numeric input for direct slide jumping
      key when is_binary(key) ->
        case Integer.parse(key) do
          {num, ""} when num > 0 -> {:goto_slide, num - 1}
          _ -> :unknown
        end

      # Unknown/unsupported keys
      _ ->
        :unknown
    end
  end

  defp process_navigation_command(command, presentation) do
    case command do
      :next_slide ->
        if Presentation.has_next?(presentation) do
          {:ok, Presentation.next_slide(presentation)}
        else
          # Stay on last slide
          {:ok, presentation}
        end

      :prev_slide ->
        if Presentation.has_prev?(presentation) do
          {:ok, Presentation.prev_slide(presentation)}
        else
          # Stay on first slide
          {:ok, presentation}
        end

      :first_slide ->
        {:ok, Presentation.goto_slide(presentation, 0)}

      :last_slide ->
        last_index = Presentation.slide_count(presentation) - 1
        {:ok, Presentation.goto_slide(presentation, last_index)}

      {:goto_slide, index} ->
        {:ok, Presentation.goto_slide(presentation, index)}

      :refresh ->
        {:ok, presentation}

      :help ->
        show_help()
        {:ok, presentation}

      :quit ->
        {:quit}

      :unknown ->
        # Ignore unknown commands
        {:ok, presentation}

      _ ->
        {:error, :invalid_command}
    end
  end

  defp show_help do
    Terminal.clear_screen()
    {width, height} = Terminal.get_dimensions()

    help_text = """
    #{Terminal.style_text("PRESENTATION NAVIGATION HELP", :bright_cyan, :bold)}

    #{Terminal.style_text("Navigation:", :bright_yellow, :bold)}
    Enter             Next slide
    p + Enter         Previous slide
    0 + Enter         First slide
    $ + Enter         Last slide
    1-9 + Enter       Jump to slide number

    #{Terminal.style_text("Actions:", :bright_yellow, :bold)}
    r + Enter         Refresh/redraw
    ? + Enter         Show this help
    q + Enter         Quit presentation

    #{Terminal.style_text("💡 Tip:", :bright_green, :bold)}
    #{Terminal.style_text("Just press Enter to advance through slides!", :bright_green, nil)}

    #{Terminal.style_text("Press Enter to continue...", :bright_green, nil)}
    """

    # Center the help text
    lines = String.split(help_text, "\n")
    vertical_offset = div(height - length(lines), 2)

    Enum.with_index(lines, vertical_offset)
    |> Enum.each(fn {line, row} ->
      centered = Terminal.center_text(line, width)
      Terminal.print_at(row, 1, centered)
    end)

    # Wait for any key
    Input.get_input()
  end

  defp configure_terminal do
    # Hide cursor for presentation mode
    Terminal.hide_cursor()

    IO.puts("📍 Navigation: Press Enter to advance, 'p'+Enter to go back, 'q'+Enter to quit")
    IO.puts("   For help, press '?'+Enter at any time")
  end

  defp restore_terminal do
    Input.disable_raw_mode()
    Terminal.show_cursor()
    Terminal.clear_screen()
    # Flush any remaining output
    IO.puts("")
  end
end
