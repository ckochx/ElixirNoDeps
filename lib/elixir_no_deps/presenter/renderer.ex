defmodule ElixirNoDeps.Presenter.Renderer do
  @moduledoc """
  Renders presentation slides to the terminal.

  Handles:
  - Slide content rendering with markdown-like formatting
  - Status bar with navigation info
  - Theme application
  - Content centering and padding
  """

  alias ElixirNoDeps.Presenter.AsciiProcessor
  alias ElixirNoDeps.Presenter.ImageRenderer
  alias ElixirNoDeps.Presenter.Presentation
  alias ElixirNoDeps.Presenter.Slide
  alias ElixirNoDeps.Presenter.Terminal

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
    # Leave more padding on sides for better text-image layout
    |> Terminal.wrap_text(width - 8)
    # Leave space for status bar and padding
    |> Enum.take(available_height - 3)
  end

  @doc """
  Processes basic markdown formatting in slide content.
  """
  @spec process_markdown_formatting(String.t()) :: String.t()
  def process_markdown_formatting(content) do
    content
    |> process_images()
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
    # Reserve space for status bar
    available_height = height - 2

    # Extract images and text content separately
    {text_content, images} = extract_images_and_text(slide.content)

    # Render content with side-by-side layout if images exist
    if Enum.empty?(images) do
      render_text_only_content(text_content, width, available_height)
    else
      render_side_by_side_content(text_content, images, width, available_height)
    end

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
    "Enter: Next | p: Prev | ?: Help | q: Quit"
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

      formatted_lines =
        Enum.map(code_lines, fn line ->
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

  defp process_images(content) do
    # Images are now handled separately in side-by-side layout
    # This function only returns content unchanged since ASCII processing 
    # is handled by AsciiProcessor.process_ascii_art in process_markdown_formatting
    content
  end


  defp render_image_error(image_path, reason) do
    Terminal.style_text("[Image Error: #{image_path} - #{reason}]", :bright_red, nil)
  end

  defp extract_images_and_text(content) do
    # Find image references but exclude ASCII art (which should stay inline)
    image_matches = Regex.scan(~r/!\[(?!ascii)(?:small|large|thumbnail|[^\]]*)\]\([^)]+\)/, content)
    images = Enum.map(image_matches, &List.first/1)
    
    # Remove images from text content but leave ASCII art inline
    text_content = Enum.reduce(images, content, fn image, acc ->
      String.replace(acc, image, "")
    end)
    |> String.replace(~r/\n\s*\n\s*\n/, "\n\n")  # Clean up extra newlines
    |> String.trim()
    
    {text_content, images}
  end

  defp render_text_only_content(text_content, width, available_height) do
    content_lines = render_content(text_content, width, available_height)
    
    # Calculate vertical centering
    content_height = length(content_lines)
    vertical_padding = max(0, div(available_height - content_height, 2))

    # Render content lines centered
    Enum.with_index(content_lines, vertical_padding + 1)
    |> Enum.each(fn {line, row} ->
      centered_line = Terminal.center_text(line, width)
      Terminal.print_at(row, 1, centered_line)
    end)
  end

  defp render_side_by_side_content(text_content, images, width, available_height) do
    # Reserve space for images on the right side
    image_width = min(div(width, 3), 80)  # Use up to 1/3 of screen for images
    text_width = width - image_width - 4  # Leave some padding
    
    # Process text content for left side
    text_lines = text_content
    |> process_markdown_formatting()
    |> Terminal.wrap_text(text_width - 4)  # Extra padding for text
    |> Enum.take(available_height - 3)
    
    # Render images on right side
    rendered_images = render_images_for_layout(images, image_width)
    
    # Calculate layout positioning
    text_height = length(text_lines)
    image_height = count_image_lines(rendered_images)
    
    # Start rendering from appropriate vertical position
    max_content_height = max(text_height, image_height)
    start_row = max(1, div(available_height - max_content_height, 2))
    
    # Render text on left side
    Enum.with_index(text_lines, start_row)
    |> Enum.each(fn {line, row} ->
      Terminal.print_at(row, 2, line)  # Small left margin
    end)
    
    # Render images on right side
    image_start_col = text_width + 4
    render_images_at_position(rendered_images, start_row, image_start_col)
  end

  defp render_images_for_layout(images, max_width) do
    Enum.map(images, fn image_markdown ->
      # Process the image markdown to get rendered content
      case process_single_image(image_markdown, max_width) do
        {:ok, rendered} -> rendered
        {:error, reason} -> render_image_error(image_markdown, reason)
      end
    end)
  end

  defp process_single_image(image_markdown, max_width) do
    # Extract image path and mode from markdown
    case Regex.run(~r/!\[([^\]]*)\]\(([^)]+)\)/, image_markdown) do
      [_, alt_text, image_path] ->
        # Determine sizing based on alt text
        # Scale pixel dimensions based on terminal width (rough approximation: 8 pixels per character)
        # Add safety checks to prevent crashes
        IO.puts("DEBUG: max_width received: #{inspect(max_width)}")
        safe_max_width = max(max_width || 80, 40)  # Fallback if max_width is nil/invalid
        # For Debian, ensure larger minimum size since terminal detection might be off
        min_scale = case System.cmd("lsb_release", ["-i"], stderr_to_stdout: true) do
          {output, 0} when output =~ "Debian" -> 600  # Larger minimum for Debian
          _ -> 400  # Standard minimum
        end
        base_scale = max(safe_max_width * 6, min_scale)
        IO.puts("DEBUG: safe_max_width: #{safe_max_width}, base_scale: #{base_scale}")
        
        opts = case alt_text do
          "small" -> [width: max(div(base_scale, 2), 200), height: max(div(base_scale, 3), 150)]
          "large" -> [width: min(base_scale * 2, 800), height: min(base_scale, 600)]
          "thumbnail" -> [width: max(div(base_scale, 3), 150), height: max(div(base_scale, 4), 100)]
          _ -> [width: max(base_scale, 400), height: max(div(base_scale * 3, 4), 300)]
        end
        
        try do
          ImageRenderer.render_image(image_path, opts)
        rescue
          error ->
            IO.puts("ERROR: Image rendering failed: #{inspect(error)}")
            {:error, "Image rendering failed: #{Exception.message(error)}"}
        end
      
      _ ->
        {:error, "Invalid image format"}
    end
  end

  defp count_image_lines(rendered_images) do
    rendered_images
    |> Enum.map(&String.split(&1, "\n"))
    |> Enum.map(&length/1)
    |> Enum.sum()
  end

  defp render_images_at_position(rendered_images, start_row, start_col) do
    {_, _} = Enum.reduce(rendered_images, {start_row, start_col}, fn rendered_image, {current_row, col} ->
      lines = String.split(rendered_image, "\n")
      
      # Render each line of the image
      Enum.with_index(lines, current_row)
      |> Enum.each(fn {line, row} ->
        Terminal.print_at(row, col, line)
      end)
      
      # Move to next position for next image
      {current_row + length(lines) + 1, col}  # Add spacing between images
    end)
  end
end
