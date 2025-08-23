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

  alias ElixirNoDeps.Presenter.{Presentation, Renderer, Terminal, RawInput}

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

  # Private functions

  defp navigation_loop do
    case get_raw_key_input() do
      :quit ->
        :ok
      command ->
        case navigate(command) do
          :quit -> :ok
          :ok -> 
            render_current_slide()
            navigation_loop()
          :error ->
            navigation_loop()
        end
    end
  end

  defp get_raw_key_input do
    case RawInput.get_raw_key() do
      # Quit commands
      "q" -> :quit
      "Q" -> :quit
      :ctrl_c -> :quit
      :ctrl_d -> :quit
      
      # Next slide commands
      " " -> :next_slide          # Spacebar (primary)
      "n" -> :next_slide          # n key
      "j" -> :next_slide          # vim down
      :arrow_right -> :next_slide  # Right arrow
      :arrow_down -> :next_slide   # Down arrow
      :enter -> :next_slide        # Enter key
      
      # Previous slide commands  
      "p" -> :prev_slide          # p key
      "k" -> :prev_slide          # vim up
      "h" -> :prev_slide          # vim left
      :arrow_left -> :prev_slide   # Left arrow
      :arrow_up -> :prev_slide     # Up arrow
      :backspace -> :prev_slide    # Backspace
      
      # Navigation shortcuts
      "0" -> :first_slide         # Go to first slide
      "$" -> :last_slide          # Go to last slide
      :home -> :first_slide       # Home key
      :end -> :last_slide         # End key
      
      # Utility commands
      "r" -> :refresh             # Refresh/redraw
      "?" -> :help                # Show help
      "/" -> :help                # Alternative help
      :f1 -> :help                # F1 for help
      
      # Handle numeric input for direct slide jumping
      key when is_binary(key) ->
        case Integer.parse(key) do
          {num, ""} when num > 0 -> {:goto_slide, num - 1}
          _ -> :unknown
        end
      
      # Handle special keys
      {:alt, key} -> {:alt_key, key}
      {:function, key} -> {:function_key, key}
      {:sequence, seq} -> {:sequence, seq}
      
      # Unknown/unsupported keys
      _ -> :unknown
    end
  end

  # Legacy method kept for compatibility
  defp get_key_input do
    case IO.getn("", 1) do
      "q" -> :quit
      "Q" -> :quit
      " " -> :next_slide
      "n" -> :next_slide
      "j" -> :next_slide
      "p" -> :prev_slide
      "k" -> :prev_slide
      "h" -> :prev_slide
      "0" -> :first_slide
      "$" -> :last_slide
      "r" -> :refresh
      "?" -> :help
      "\e" -> 
        # Handle escape sequences (arrow keys)
        handle_escape_sequence()
      key ->
        # Handle numeric input for slide jumping
        case Integer.parse(key) do
          {num, ""} when num > 0 -> {:goto_slide, num - 1}
          _ -> :unknown
        end
    end
  end

  defp handle_escape_sequence do
    # Read the next character to determine arrow key
    case IO.getn("", 1) do
      "[" ->
        case IO.getn("", 1) do
          "C" -> :next_slide  # Right arrow
          "D" -> :prev_slide  # Left arrow
          "A" -> :prev_slide  # Up arrow  
          "B" -> :next_slide  # Down arrow
          _ -> :unknown
        end
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
          {:ok, presentation} # Stay on last slide
        end

      :prev_slide ->
        if Presentation.has_prev?(presentation) do
          {:ok, Presentation.prev_slide(presentation)}
        else
          {:ok, presentation} # Stay on first slide
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
        {:ok, presentation} # Ignore unknown commands

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
    Space, →, ↓, n, j, Enter    Next slide
    ←, ↑, p, k, h, Backspace   Previous slide
    0, Home                    First slide
    $, End                     Last slide
    1-9                        Jump to slide number
    
    #{Terminal.style_text("Actions:", :bright_yellow, :bold)}
    r                 Refresh/redraw
    ?, /, F1          Show this help
    q, Q, Ctrl+C, Ctrl+D    Quit presentation
    
    #{Terminal.style_text("✨ Raw keyboard input enabled!", :bright_magenta, nil)}
    #{Terminal.style_text("No need to press Enter - just press any key!", :bright_green, nil)}
    
    #{Terminal.style_text("Press any key to continue...", :bright_green, nil)}
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
    RawInput.get_raw_key()
  end

  defp configure_terminal do
    # Hide cursor for presentation mode
    Terminal.hide_cursor()
    
    # Enable raw mode for single-key input
    RawInput.enable_raw_mode()
  end

  defp restore_terminal do
    # Restore normal terminal mode
    RawInput.disable_raw_mode()
    Terminal.show_cursor()
    Terminal.clear_screen()
  end
end