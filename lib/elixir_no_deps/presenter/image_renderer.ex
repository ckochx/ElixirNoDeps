defmodule ElixirNoDeps.Presenter.ImageRenderer do
  @moduledoc """
  Renders images directly in terminals using various protocols.

  Supported protocols:
  - iTerm2 Inline Images
  - Kitty Graphics Protocol  
  - Sixel Graphics
  - Unicode blocks (fallback)
  """

  @doc """
  Renders an image directly in the terminal using the best available protocol.

  Returns the rendered content as a string with terminal escape sequences.
  """
  @spec render_image(String.t(), keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def render_image(image_path, opts \\ []) do
    with {:ok, _} <- File.stat(image_path),
         protocol <- detect_terminal_capabilities() do
      render_with_protocol(image_path, protocol, opts)
    else
      {:error, :enoent} -> {:error, "Image file not found: #{image_path}"}
      {:error, reason} -> {:error, "Failed to access image: #{reason}"}
    end
  end

  @doc """
  Detects terminal capabilities and returns the best supported protocol.
  """
  @spec detect_terminal_capabilities() :: :iterm2 | :kitty | :sixel | :unicode_blocks
  def detect_terminal_capabilities do
    cond do
      iterm2_supported?() -> :iterm2
      kitty_supported?() -> :kitty
      sixel_supported?() -> :sixel
      true -> :unicode_blocks
    end
  end

  @doc """
  Renders an image using a specific protocol.
  """
  @spec render_with_protocol(String.t(), atom(), keyword()) ::
          {:ok, String.t()} | {:error, String.t()}
  def render_with_protocol(image_path, protocol, opts \\ [])

  def render_with_protocol(image_path, :iterm2, opts) do
    render_iterm2(image_path, opts)
  end

  def render_with_protocol(image_path, :kitty, opts) do
    render_kitty(image_path, opts)
  end

  def render_with_protocol(image_path, :sixel, opts) do
    render_sixel(image_path, opts)
  end

  def render_with_protocol(image_path, :unicode_blocks, opts) do
    render_unicode_blocks(image_path, opts)
  end

  # Private functions


  defp iterm2_supported? do
    System.get_env("TERM_PROGRAM") == "iTerm.app"
  end

  defp kitty_supported? do
    System.get_env("TERM") =~ "kitty" or terminal_responds_to_kitty_query?()
  end

  defp sixel_supported? do
    # Check if terminal supports sixel graphics
    term = System.get_env("TERM", "")
    term =~ "xterm" or term =~ "screen" or System.get_env("COLORTERM") != nil
  end

  defp terminal_responds_to_kitty_query? do
    # For now, just check TERM variable
    # In a more robust implementation, we would send a query and wait for response
    System.get_env("TERM") =~ "kitty"
  end

  defp render_iterm2(image_path, opts) do
    with {:ok, image_data} <- File.read(image_path) do
      encoded = Base.encode64(image_data)
      file_size = byte_size(image_data)
      encoded_size = byte_size(encoded)

      size_params = build_iterm2_size_params(opts, file_size, encoded_size)
      
      # Create image with newline for better spacing
      escape_sequence = "\e]1337;File=#{size_params}:#{encoded}\a\n"
      {:ok, escape_sequence}
    else
      {:error, reason} -> {:error, "Failed to read image: #{reason}"}
    end
  end

  defp render_kitty(image_path, _opts) do
    with {:ok, image_data} <- File.read(image_path) do
      encoded = Base.encode64(image_data)

      # Kitty graphics escape sequence
      # a=T means transmission, f=100 means PNG format, m=1 means more data follows
      escape_sequence = "\e_Ga=T,f=100,m=1;#{encoded}\e\\"
      {:ok, escape_sequence}
    else
      {:error, reason} -> {:error, "Failed to read image: #{reason}"}
    end
  end

  defp render_sixel(image_path, opts) do
    width = Keyword.get(opts, :width, 250)
    height = Keyword.get(opts, :height, 250)

    # Debug: print the command we're about to run
    cmd_args = ["-display", "none", image_path, "-resize", "#{width}x#{height}", "sixel:-"]
    IO.puts("DEBUG: Running magick #{Enum.join(cmd_args, " ")}")
    IO.puts("DEBUG: Width: #{width}, Height: #{height}")
    IO.puts("DEBUG: Options passed: #{inspect(opts)}")
    IO.puts("DEBUG: Current working directory: #{File.cwd!()}")
    IO.puts("DEBUG: Image file exists? #{File.exists?(image_path)}")

    # For GIFs, try without resizing first for better performance
    result = if String.ends_with?(String.downcase(image_path), ".gif") do
      IO.puts("DEBUG: Processing GIF without resizing for performance")
      case System.cmd("img2sixel", [image_path], stderr_to_stdout: true) do
        {sixel_data, 0} -> 
          IO.puts("DEBUG: img2sixel successful (no resize)")
          {:ok, sixel_data}
        {error, _} ->
          IO.puts("DEBUG: img2sixel failed: #{error}, trying ImageMagick without resize")
          gif_cmd_args = ["-display", "none", image_path, "sixel:-"]
          System.cmd("magick", gif_cmd_args, stderr_to_stdout: true)
      end
    else
      System.cmd("magick", cmd_args, stderr_to_stdout: true)
    end

    case result do
      {sixel_data, 0} -> 
        IO.puts("DEBUG: Sixel conversion successful")
        {:ok, sixel_data}
      {error, exit_code} -> 
        IO.puts("DEBUG: Sixel conversion failed with exit code #{exit_code}")
        IO.puts("DEBUG: Error output: #{error}")
        {:error, "ImageMagick failed: #{error}"}
    end
  end

  defp render_unicode_blocks(image_path, _opts) do
    # Fallback to ASCII art using existing AsciiProcessor
    alias ElixirNoDeps.Presenter.AsciiProcessor

    case AsciiProcessor.process_ascii_art("![ascii](#{image_path})") do
      processed when is_binary(processed) -> {:ok, processed}
      _ -> {:error, "Failed to generate ASCII art"}
    end
  end

  defp build_iterm2_size_params(opts, file_size, _encoded_size) do
    # Start with basic parameters
    params = [
      "size=#{file_size}",
      "inline=1",
      "preserveAspectRatio=1"  # Always preserve aspect ratio
    ]

    # Use smaller default sizes for better screen sharing
    width = Keyword.get(opts, :width, 80)   # Much smaller default
    height = Keyword.get(opts, :height, 20) # Much smaller default
    
    # Ensure reasonable maximum sizes - much more conservative
    max_width = min(width, 120)  # Lower cap
    max_height = min(height, 30) # Lower cap

    params = ["width=#{max_width}" | params]
    params = ["height=#{max_height}" | params]

    Enum.join(params, ";")
  end
end
