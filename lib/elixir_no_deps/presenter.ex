defmodule ElixirNoDeps.Presenter do
  @moduledoc """
  Main entry point for the terminal presentation system.

  Provides a simple API to run presentations from markdown files.
  """

  alias ElixirNoDeps.Presenter.Input
  alias ElixirNoDeps.Presenter.Navigator
  alias ElixirNoDeps.Presenter.Parser
  alias ElixirNoDeps.Presenter.Terminal

  @doc """
  Runs a presentation from a markdown file.

  ## Examples

      # Run a presentation
      ElixirNoDeps.Presenter.run("slides.md")

      # Run with options
      ElixirNoDeps.Presenter.run("slides.md", theme: "dark")
  """
  @spec run(String.t(), keyword()) :: :ok | {:error, String.t()}
  def run(file_path, opts \\ []) do
    case Parser.parse_file(file_path) do
      {:ok, presentation} ->
        # Apply any runtime options
        updated_presentation = apply_options(presentation, opts)

        # Check if presentation has slides
        if ElixirNoDeps.Presenter.Presentation.slide_count(updated_presentation) == 0 do
          IO.puts("No slides found in presentation file.")
          {:error, "No slides found"}
        else
          # Start the navigation system
          run_presentation_with_error_handling(updated_presentation)
        end

      {:error, reason} ->
        IO.puts("Failed to load presentation: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Runs a presentation from a Presentation struct.
  """
  @spec run_presentation(ElixirNoDeps.Presenter.Presentation.t()) :: :ok
  def run_presentation(presentation) do
    # Setup cleanup handler
    setup_cleanup_handler()

    IO.puts("Starting presentation...")
    IO.puts("Press Enter to advance, '?' for help, or 'q' to quit\n")

    # Small delay to let user see the message
    Process.sleep(1000)

    # Start the navigator
    case Navigator.run(presentation) do
      :ok ->
        Terminal.clear_screen()
        IO.puts("Presentation ended.")
        :ok

      :error ->
        Terminal.show_cursor()
        IO.puts("Error running presentation.")
        :error
    end
  end

  @doc """
  Creates a simple demo presentation for testing.
  """
  @spec demo() :: :ok
  def demo do
    demo_content = """
    ---
    title: "ElixirNoDeps Presenter Demo"
    author: "Demo User"
    theme: "default"
    ---

    # Welcome! 🎉

    This is a **demo presentation** built with Elixir.

    Press the *space bar* or *arrow keys* to navigate.

    ---

    # Features

    ## Core Capabilities
    - **Markdown-based** slides
    - **Keyboard navigation**
    - **ANSI colors** and formatting
    - **No external dependencies**

    ## Navigation
    - `Space`, `→`, `j`: Next slide
    - `←`, `k`, `h`: Previous slide
    - `q`: Quit

    ---

    # Code Example

    Here's some Elixir code:

    ```elixir
    defmodule Demo do
      def hello do
        "Hello, world!"
      end
    end
    ```

    Pretty neat, right?

    ---

    # Lists Work Too

    ## Unordered Lists
    - First item
    - Second item
    - Third item

    ## Numbered Lists
    1. Step one
    2. Step two
    3. Step three

    ---

    # Thank You!

    ## Questions?

    This presentation was built with:
    - **Elixir** for the logic
    - **Pattern matching** for parsing
    - **GenServer** for state management
    - **ANSI escape codes** for terminal control

    Press `q` to exit the demo.
    """

    # Write temporary demo file
    demo_file = "/tmp/elixir_presenter_demo.md"
    File.write!(demo_file, demo_content)

    # Run the demo
    result = run(demo_file)

    # Cleanup
    File.rm(demo_file)

    result
  end

  # Private functions

  defp apply_options(presentation, opts) do
    # Apply any runtime configuration options
    Enum.reduce(opts, presentation, fn
      {:theme, theme}, acc -> %{acc | theme: theme}
      {:author, author}, acc -> %{acc | author: author}
      {:title, title}, acc -> %{acc | title: title}
      _, acc -> acc
    end)
  end

  defp run_presentation_with_error_handling(presentation) do
    try do
      result = Navigator.run(presentation)
      # Ensure terminal is always restored
      Input.disable_raw_mode()
      Terminal.show_cursor()
      result
    rescue
      error ->
        # Ensure terminal restoration on error
        Input.disable_raw_mode()
        Terminal.show_cursor()
        Terminal.clear_screen()
        IO.puts("\nError during presentation: #{inspect(error)}")
        :error
    catch
      :exit, reason ->
        # Ensure terminal restoration on exit
        Input.disable_raw_mode()
        Terminal.show_cursor()
        Terminal.clear_screen()
        IO.puts("\nPresentation interrupted: #{inspect(reason)}")
        :ok
    end
  end

  defp setup_cleanup_handler do
    # Ensure cursor is restored on exit
    Process.flag(:trap_exit, true)

    # Handle Ctrl+C gracefully
    :erlang.process_flag(:trap_exit, true)
  end
end
