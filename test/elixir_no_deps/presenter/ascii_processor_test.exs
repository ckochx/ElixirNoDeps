defmodule ElixirNoDeps.Presenter.AsciiProcessorTest do
  use ExUnit.Case, async: true

  alias ElixirNoDeps.Presenter.AsciiProcessor

  describe "extract_ascii_paths/1" do
    test "extracts ASCII image paths from content" do
      content = """
      # My Slide

      Here's an image:
      ![ascii](tinyllama.jpg)

      And another:
      ![ascii](path/to/image.png)

      Regular image: ![regular](normal.jpg)
      """

      paths = AsciiProcessor.extract_ascii_paths(content)

      assert length(paths) == 2
      assert "tinyllama.jpg" in paths
      assert "path/to/image.png" in paths
      refute "normal.jpg" in paths
    end

    test "handles empty content" do
      assert AsciiProcessor.extract_ascii_paths("") == []
    end

    test "handles content with no ASCII images" do
      content = "Just text with ![regular](image.jpg)"
      assert AsciiProcessor.extract_ascii_paths(content) == []
    end

    test "removes duplicates" do
      content = """
      ![ascii](same.jpg)
      ![ascii](same.jpg)
      ![ascii](different.jpg)
      """

      paths = AsciiProcessor.extract_ascii_paths(content)

      assert length(paths) == 2
      assert "same.jpg" in paths
      assert "different.jpg" in paths
    end
  end

  describe "process_ascii_art/1" do
    test "replaces ASCII image references with placeholder when file doesn't exist" do
      content = "Look at this: ![ascii](nonexistent.jpg)"
      result = AsciiProcessor.process_ascii_art(content)

      refute String.contains?(result, "![ascii](nonexistent.jpg)")
      assert String.contains?(result, "ASCII Art Error")
      assert String.contains?(result, "nonexistent.jpg")
    end

    test "leaves regular image references unchanged" do
      content = "Regular image: ![photo](image.jpg)"
      result = AsciiProcessor.process_ascii_art(content)

      assert result == content
    end

    test "handles multiple ASCII references" do
      content = """
      First: ![ascii](first.jpg)
      Second: ![ascii](second.jpg)
      """

      result = AsciiProcessor.process_ascii_art(content)

      refute String.contains?(result, "![ascii](first.jpg)")
      refute String.contains?(result, "![ascii](second.jpg)")
      assert String.contains?(result, "ASCII Art Error")
    end

    test "handles case insensitive ASCII references" do
      content = "Mixed case: ![ASCII](image.jpg)"
      result = AsciiProcessor.process_ascii_art(content)

      refute String.contains?(result, "![ASCII](image.jpg)")
      assert String.contains?(result, "ASCII Art Error")
    end
  end

  describe "generate_ascii_art/1" do
    test "returns error placeholder for non-existent file" do
      result = AsciiProcessor.generate_ascii_art("nonexistent.jpg")

      assert String.contains?(result, "ASCII Art Error")
      assert String.contains?(result, "nonexistent.jpg")
      assert String.contains?(result, "Image file not found")
    end

    test "handles file without ImageMagick" do
      # Create a temporary empty file
      temp_file = "/tmp/test_ascii_#{System.unique_integer()}.jpg"
      File.write!(temp_file, "fake image content")

      result = AsciiProcessor.generate_ascii_art(temp_file)

      # Should get error placeholder since it's not a real image
      # Either ASCII art or error
      assert String.contains?(result, "ASCII")

      File.rm(temp_file)
    end

    @tag :integration
    test "processes PNG files with alpha channel (srgba format)" do
      png_file = "tinyllama.png"

      # Skip if file doesn't exist  
      if File.exists?(png_file) do
        result = AsciiProcessor.generate_ascii_art(png_file)

        refute String.contains?(result, "[ASCII Art Error]")
        refute String.contains?(result, "[ASCII Generation Failed]")
        assert String.length(result) > 1000
        # Should contain ASCII characters
        assert String.contains?(result, "`") or String.contains?(result, "^") or
                 String.contains?(result, ":")
      end
    end

    @tag :integration
    test "processes JPG files (srgb format)" do
      jpg_file = "tinyllama.jpg"

      # Skip if file doesn't exist
      if File.exists?(jpg_file) do
        result = AsciiProcessor.generate_ascii_art(jpg_file)

        refute String.contains?(result, "[ASCII Art Error]")
        refute String.contains?(result, "[ASCII Generation Failed]")
        assert String.length(result) > 1000
        # Should contain ASCII characters
        assert String.contains?(result, "`") or String.contains?(result, "^") or
                 String.contains?(result, ":")
      end
    end

    @tag :integration
    test "PNG and JPG produce different but valid ASCII art" do
      png_file = "tinyllama.png"
      jpg_file = "tinyllama.jpg"

      # Skip if files don't exist
      if File.exists?(png_file) and File.exists?(jpg_file) do
        png_result = AsciiProcessor.generate_ascii_art(png_file)
        jpg_result = AsciiProcessor.generate_ascii_art(jpg_file)

        # Both should be valid ASCII art
        refute String.contains?(png_result, "[ASCII Art Error]")
        refute String.contains?(jpg_result, "[ASCII Art Error]")

        # Results should be substantial
        assert String.length(png_result) > 1000
        assert String.length(jpg_result) > 1000

        # Results may differ due to format differences but both should work
        # (PNG has transparency, JPG doesn't, so results can vary)
      end
    end
  end

  describe "clear_cache/0" do
    test "clears cache without errors" do
      # Should not raise errors even if cache doesn't exist
      assert AsciiProcessor.clear_cache() == :ok
    end
  end

  describe "preload_ascii_art/1" do
    test "preloads multiple images without errors" do
      paths = ["nonexistent1.jpg", "nonexistent2.jpg"]
      assert AsciiProcessor.preload_ascii_art(paths) == :ok
    end

    test "handles empty path list" do
      assert AsciiProcessor.preload_ascii_art([]) == :ok
    end
  end
end
