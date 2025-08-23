defmodule ElixirNoDeps.Presenter.Renderer do
  @moduledoc """
  Renders presentation slides to the terminal.
  
  Handles:
  - Slide content rendering with markdown-like formatting
  - Status bar with navigation info
  - Theme application
  - Content centering and padding
  """

  alias ElixirNoDeps.Presenter.{Presentation, Slide, Terminal, AsciiProcessor}

  @doc """
  Renders a presentation slide to the terminal.
  """
  @spec render_slide(Presentation.t()) :: :ok
  def render_slide(%Presentation{} = presentation) do
    Terminal.clear_screen()
    Terminal.hide_cursor()
    
    {width, height} = Terminal.get_dimensions()
    current_slide = Presentation.current_slide(presentation)
    
    case current_slide do
      nil ->
        render_empty_presentation(width, height)
      slide ->
        render_slide_content(slide, presentation, width, height)
    end
    
    :ok
  end

  @doc """
  Renders the status bar at the bottom of the screen.
  """
  @spec render_status_bar(Presentation.t(), pos_integer(), pos_integer()) :: :ok
  def render_status_bar(%Presentation{} = presentation, width, height) do
    current_num = Presentation.current_slide_number(presentation)
    total = Presentation.slide_count(presentation)
    
    # Status line content
    left_status = "#{current_num}/#{total}"
    right_status = navigation_help()
    
    # Calculate positioning
    status_line = format_status_line(left_status, right_status, width)
    
    # Render at bottom of screen
    Terminal.print_at(height, 1, Terminal.style_text(status_line, :bright_black, nil))
    
    :ok
  end

  @doc """
  Renders slide content with basic markdown-style formatting.
  """
  @spec render_content(String.t(), pos_integer(), pos_integer()) :: [String.t()]
  def render_content(content, width, available_height) do
    content
    |> process_markdown_formatting()
    |> Terminal.wrap_text(width - 4) # Leave padding on sides
    |> Enum.take(available_height - 3) # Leave space for status bar and padding
  end

  @doc """
  Processes basic markdown formatting in slide content.
  """
  @spec process_markdown_formatting(String.t()) :: String.t()
  def process_markdown_formatting(content) do
    content
    |> AsciiProcessor.process_ascii_art()
    |> process_headers()
    |> process_emphasis()
    |> process_code_blocks()
    |> process_lists()
  end

  # Private functions

  defp render_empty_presentation(width, height) do
    message = "No slides to display"
    centered = Terminal.center_text(message, width)
    middle_row = div(height, 2)
    
    Terminal.print_at(middle_row, 1, Terminal.style_text(centered, :bright_red, :bold))
  end

  defp render_slide_content(%Slide{} = slide, presentation, width, height) do
    available_height = height - 2 # Reserve space for status bar
    
    # Process and render slide content
    content_lines = render_content(slide.content, width, available_height)
    
    # Calculate vertical centering
    content_height = length(content_lines)
    vertical_padding = max(0, div(available_height - content_height, 2))
    
    # Render content lines
    Enum.with_index(content_lines, vertical_padding + 1)
    |> Enum.each(fn {line, row} ->
      centered_line = Terminal.center_text(line, width)
      Terminal.print_at(row, 1, centered_line)
    end)
    
    # Render status bar
    render_status_bar(presentation, width, height)
  end

  defp format_status_line(left, right, width) do
    right_length = Terminal.visible_length(right)
    left_length = Terminal.visible_length(left)
    
    if left_length + right_length + 2 >= width do
      # Not enough space, just show left status
      String.pad_trailing(left, width)
    else
      # Create status line with left and right content
      middle_padding = width - left_length - right_length
      left <> String.duplicate(" ", middle_padding) <> right
    end
  end

  defp navigation_help do
    "Space/→: Next | ←: Prev | ?: Help | q: Quit"
  end

  defp process_headers(content) do
    content
    |> String.replace(~r/^# (.+)$/m, fn match ->
      title = String.replace(match, ~r/^# /, "")
      Terminal.style_text(title, :bright_cyan, :bold)
    end)
    |> String.replace(~r/^## (.+)$/m, fn match ->
      title = String.replace(match, ~r/^## /, "")
      Terminal.style_text(title, :bright_yellow, :bold)
    end)
    |> String.replace(~r/^### (.+)$/m, fn match ->
      title = String.replace(match, ~r/^### /, "")
      Terminal.style_text(title, :bright_white, :bold)
    end)
  end

  defp process_emphasis(content) do
    content
    # Bold: **text** or __text__
    |> String.replace(~r/\*\*([^*]+)\*\*/, fn match ->
      text = String.replace(match, ~r/^\*\*|\*\*$/, "")
      Terminal.style_text(text, nil, :bold)
    end)
    |> String.replace(~r/__([^_]+)__/, fn match ->
      text = String.replace(match, ~r/^__|__$/, "")
      Terminal.style_text(text, nil, :bold)
    end)
    # Italic: *text* or _text_
    |> String.replace(~r/\*([^*]+)\*/, fn match ->
      text = String.replace(match, ~r/^\*|\*$/, "")
      Terminal.style_text(text, nil, :italic)
    end)
    |> String.replace(~r/_([^_]+)_/, fn match ->
      text = String.replace(match, ~r/^_|_$/, "")
      Terminal.style_text(text, nil, :italic)
    end)
  end

  defp process_code_blocks(content) do
    content
    # Inline code: `code`
    |> String.replace(~r/`([^`]+)`/, fn match ->
      code = String.replace(match, ~r/^`|`$/, "")
      Terminal.style_text(code, :bright_green, nil)
    end)
    # Code blocks: ```code```
    |> String.replace(~r/```([^`]+)```/s, fn match ->
      code = String.replace(match, ~r/^```|```$/, "")
      code_lines = String.split(code, "\n")
      formatted_lines = Enum.map(code_lines, fn line ->
        Terminal.style_text("  " <> line, :green, nil)
      end)
      Enum.join(formatted_lines, "\n")
    end)
  end

  defp process_lists(content) do
    content
    # Unordered lists: - item or * item
    |> String.replace(~r/^[\s]*[-*]\s+(.+)$/m, fn match ->
      item = String.replace(match, ~r/^[\s]*[-*]\s+/, "")
      Terminal.style_text("  • #{item}", :bright_blue, nil)
    end)
    # Numbered lists: 1. item
    |> String.replace(~r/^[\s]*\d+\.\s+(.+)$/m, fn match ->
      item = String.replace(match, ~r/^[\s]*\d+\.\s+/, "")
      Terminal.style_text("    #{item}", :bright_blue, nil)
    end)
  end
end