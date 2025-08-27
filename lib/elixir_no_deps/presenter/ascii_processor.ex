defmodule ElixirNoDeps.Presenter.AsciiProcessor do
  @moduledoc """
  Processes ASCII art directives in presentation slides.

  Supports:
  - ![ascii](image_path) syntax for inline ASCII art
  - Caching of generated ASCII art for performance  
  - Integration with existing AsciiImage module
  """

  # alias ElixirNoDeps.AsciiImage
  alias ElixirNoDeps.ETSCache

  @doc """
  Processes a slide's content to replace ASCII art directives with actual ASCII art.

  Supports markdown image syntax with 'ascii' alt text:
  ![ascii](path/to/image.jpg)
  ![ascii](path/to/image.png)
  """
  @spec process_ascii_art(String.t()) :: String.t()
  def process_ascii_art(content) do
    # Match ![ascii](image_path) patterns
    ascii_regex = ~r/!\[ascii\]\(([^)]+)\)/i

    String.replace(content, ascii_regex, fn match ->
      # Extract the image path from the match
      case Regex.run(ascii_regex, match) do
        [_full_match, image_path] ->
          generate_ascii_art(String.trim(image_path))

        _ ->
          # Return original if parsing fails
          match
      end
    end)
  end

  @doc """
  Generates ASCII art for an image, with caching.
  """
  @spec generate_ascii_art(String.t()) :: String.t()
  def generate_ascii_art(image_path) do
    cache_key = "ascii_art:#{image_path}"

    case get_cached_ascii(cache_key) do
      {:ok, cached_art} ->
        cached_art

      :error ->
        case create_ascii_art(image_path) do
          {:ok, ascii_art} ->
            cache_ascii_art(cache_key, ascii_art)
            ascii_art

          {:error, reason} ->
            create_error_placeholder(image_path, reason)
        end
    end
  end

  @doc """
  Preloads ASCII art for all images in a presentation to improve performance.
  """
  @spec preload_ascii_art([String.t()]) :: :ok
  def preload_ascii_art(image_paths) do
    # Process images in parallel using tasks
    tasks =
      Enum.map(image_paths, fn path ->
        Task.async(fn -> generate_ascii_art(path) end)
      end)

    # Wait for all tasks to complete
    Task.await_many(tasks, :infinity)

    :ok
  end

  @doc """
  Extracts all ASCII art image paths from slide content.
  """
  @spec extract_ascii_paths(String.t()) :: [String.t()]
  def extract_ascii_paths(content) do
    ascii_regex = ~r/!\[ascii\]\(([^)]+)\)/i

    Regex.scan(ascii_regex, content)
    |> Enum.map(fn [_full_match, path] -> String.trim(path) end)
    |> Enum.uniq()
  end

  @doc """
  Clears the ASCII art cache.
  Note: Current ETS implementation doesn't support bulk operations.
  """
  @spec clear_cache() :: :ok
  def clear_cache do
    # TODO: ETSCache doesn't currently support keys() or delete() operations
    # For now, we'll let entries expire naturally via TTL
    :ok
  end

  # Private functions

  defp get_cached_ascii(cache_key) do
    try do
      case ETSCache.get(cache_key) do
        nil -> :error
        value -> {:ok, value}
      end
    rescue
      _ -> :error
    end
  end

  defp cache_ascii_art(cache_key, ascii_art) do
    try do
      # Cache for 1 hour (3600 seconds)
      ETSCache.put(cache_key, ascii_art, ttl: 3600)
    rescue
      # Gracefully handle cache failures
      _ -> :ok
    end
  end

  defp create_ascii_art(image_path) do
    if File.exists?(image_path) do
      try do
        # Capture the ASCII art output instead of printing it
        ascii_art = capture_ascii_output(image_path)
        {:ok, ascii_art}
      rescue
        error ->
          {:error, "Failed to generate ASCII art: #{inspect(error)}"}
      catch
        :exit, reason ->
          {:error, "Process failed: #{inspect(reason)}"}
      end
    else
      {:error, "Image file not found: #{image_path}"}
    end
  end

  defp capture_ascii_output(image_path) do
    # Use the direct matrix approach since it's more reliable
    get_ascii_matrix(image_path)
    |> Enum.map(&Enum.join/1)
    |> Enum.join("\n")
  end

  defp create_error_placeholder(image_path, reason) do
    """
    [ASCII Art Error]
    Image: #{image_path}
    Error: #{reason}

    ┌─────────────────────┐
    │   Image Loading     │
    │      Failed         │
    │                     │
    │    [  ×  ]          │
    └─────────────────────┘
    """
  end

  # # Alternative simpler implementation that works with the current AsciiImage module
  # # This version captures stdout using a different approach
  # defp capture_ascii_output_simple(image_path) do
  #   try do
  #     # Use ExUnit.CaptureIO if available, otherwise implement basic capture
  #     if Code.ensure_loaded?(ExUnit.CaptureIO) do
  #       ExUnit.CaptureIO.capture_io(fn ->
  #         AsciiImage.asciify(image_path)
  #       end)
  #     else
  #       # Fallback: create ASCII matrix directly without printing
  #       ascii_matrix = get_ascii_matrix(image_path)
  #       ascii_matrix
  #       |> Enum.map(&Enum.join/1)
  #       |> Enum.join("\n")
  #     end
  #   rescue
  #     error ->
  #       create_error_placeholder(image_path, inspect(error))
  #   end
  # end

  # Direct access to the ASCII matrix without printing
  defp get_ascii_matrix(image_path) do
    try do
      # This mirrors the logic from AsciiImage but returns instead of printing
      {raw_pixel_data, 0} = System.cmd("magick", ["-display", "none", image_path, "-resize", "250", "sparse-color:"])

      raw_pixel_data
      |> String.split()
      |> Enum.map(&String.split(&1, ",", parts: 3))
      |> Enum.reduce([], &pixels_to_rows/2)
      |> Enum.map(&row_rgb_values/1)
      |> Enum.map(&row_brightness_values/1)
      |> Enum.map(&row_ascii_characters/1)
    rescue
      _error ->
        [["[ASCII Generation Failed]"]]
    catch
      :exit, _reason ->
        [["[ASCII Process Failed]"]]
    end
  end

  # Copy the private functions from AsciiImage for direct matrix generation
  defp pixels_to_rows(pixel, acc) do
    row = pixel |> Enum.at(1) |> String.to_integer()

    acc =
      if Enum.at(acc, row) == nil do
        acc ++ [[]]
      else
        acc
      end

    acc |> List.replace_at(row, Enum.at(acc, row) ++ [pixel])
  end

  defp row_rgb_values(row) do
    row |> Enum.map(&pixel_rgb_value/1)
  end

  defp pixel_rgb_value(pixel) do
    color_string = pixel |> Enum.at(-1)

    # Handle both srgb(...) and srgba(...) formats
    rgb_values =
      cond do
        String.starts_with?(color_string, "srgba(") ->
          # Extract RGB values from srgba(r,g,b,a) - ignore alpha channel
          color_string
          |> String.slice(6..-2//1)
          |> String.split(",")
          # Only take first 3 values (RGB), ignore alpha
          |> Enum.take(3)
          |> Enum.map(&parse_percentage_to_rgb/1)

        String.starts_with?(color_string, "srgb(") ->
          # Extract RGB values from srgb(r,g,b)
          color_string
          |> String.slice(5..-2//1)
          |> String.split(",")
          |> Enum.map(&parse_percentage_to_rgb/1)

        true ->
          # Fallback - assume old format
          color_string
          |> String.slice(5..-2//1)
          |> String.split(",")
          |> Enum.take(3)
          |> Enum.map(&parse_percentage_to_rgb/1)
      end

    # Ensure we always have 3 RGB values
    case length(rgb_values) do
      3 -> rgb_values
      n when n > 3 -> Enum.take(rgb_values, 3)
      n when n < 3 -> rgb_values ++ List.duplicate(0, 3 - n)
    end
  end

  defp parse_percentage_to_rgb(percentage_str) do
    cleaned = String.replace(percentage_str, "%", "")

    value =
      if String.contains?(cleaned, ".") do
        String.to_float(cleaned)
      else
        String.to_integer(cleaned) |> Kernel./(1.0)
      end

    (value * 255 / 100) |> round()
  end

  defp row_brightness_values(row) do
    row
    |> Enum.map(&(Enum.sum(&1) / 3))
    |> Enum.map(&round/1)
  end

  defp row_ascii_characters(row) do
    row |> Enum.map(&brightness_to_ascii/1)
  end

  defp brightness_to_ascii(value) do
    ascii_list = "$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\\|()1{}[]?-_+~i!lI;:,\"^`"
    fraction = value / 255
    character_index = round(65 * fraction) - 1
    character = String.slice(ascii_list, character_index, 1)
    Enum.join([character, character, character])
  end
end
