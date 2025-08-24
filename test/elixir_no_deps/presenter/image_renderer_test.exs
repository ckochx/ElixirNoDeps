defmodule ElixirNoDeps.Presenter.ImageRendererTest do
  use ExUnit.Case, async: true

  alias ElixirNoDeps.Presenter.ImageRenderer

  describe "detect_terminal_capabilities/0" do
    test "detects iTerm2 when TERM_PROGRAM is iTerm.app" do
      with_env([{"TERM_PROGRAM", "iTerm.app"}], fn ->
        assert ImageRenderer.detect_terminal_capabilities() == :iterm2
      end)
    end

    test "detects kitty when TERM contains kitty" do
      with_env([{"TERM_PROGRAM", nil}, {"TERM", "xterm-kitty"}], fn ->
        assert ImageRenderer.detect_terminal_capabilities() == :kitty
      end)
    end

    test "detects sixel for xterm terminals" do
      with_env([{"TERM_PROGRAM", nil}, {"TERM", "xterm-256color"}], fn ->
        assert ImageRenderer.detect_terminal_capabilities() == :sixel
      end)
    end

    test "falls back to unicode blocks for unknown terminals" do
      with_env([{"TERM_PROGRAM", nil}, {"TERM", "unknown"}, {"COLORTERM", nil}], fn ->
        assert ImageRenderer.detect_terminal_capabilities() == :unicode_blocks
      end)
    end
  end

  describe "render_image/2" do
    setup do
      {:ok, test_image: "test/fixtures/images/test_red.jpg"}
    end

    test "returns error for non-existent file" do
      assert {:error, "Image file not found: /nonexistent/image.png"} = 
        ImageRenderer.render_image("/nonexistent/image.png")
    end

    test "renders image using detected protocol", %{test_image: test_image} do
      assert {:ok, rendered} = ImageRenderer.render_image(test_image)
      assert is_binary(rendered)
      assert String.length(rendered) > 0
    end

    test "accepts rendering options", %{test_image: test_image} do
      opts = [width: 100, height: 100]
      assert {:ok, rendered} = ImageRenderer.render_image(test_image, opts)
      assert is_binary(rendered)
    end
  end

  describe "render_with_protocol/3" do
    setup do
      {:ok, test_image: "test/fixtures/images/test_blue.png"}
    end

    test "renders using iTerm2 protocol", %{test_image: test_image} do
      assert {:ok, rendered} = ImageRenderer.render_with_protocol(test_image, :iterm2)
      assert rendered =~ "\e]1337;File="
      assert rendered =~ "\a"
      assert String.contains?(rendered, Base.encode64(File.read!(test_image)))
    end

    test "renders using kitty protocol", %{test_image: test_image} do
      assert {:ok, rendered} = ImageRenderer.render_with_protocol(test_image, :kitty)
      assert rendered =~ "\e_Ga=T,f=100,m=1;"
      assert rendered =~ "\e\\"
      assert String.contains?(rendered, Base.encode64(File.read!(test_image)))
    end

    test "renders using sixel protocol requires ImageMagick", %{test_image: test_image} do
      case System.find_executable("magick") do
        nil ->
          # Skip test if ImageMagick not available
          assert {:error, _} = ImageRenderer.render_with_protocol(test_image, :sixel)

        _magick_path ->
          assert {:ok, rendered} = ImageRenderer.render_with_protocol(test_image, :sixel)
          assert is_binary(rendered)
      end
    end

    test "renders using unicode blocks fallback", %{test_image: test_image} do
      assert {:ok, rendered} = ImageRenderer.render_with_protocol(test_image, :unicode_blocks)
      assert is_binary(rendered)
    end

    test "handles file read errors gracefully" do
      assert {:error, _reason} = ImageRenderer.render_with_protocol("/nonexistent.jpg", :iterm2)
    end
  end

  describe "protocol-specific rendering with options" do
    setup do
      {:ok, test_image: "test/fixtures/images/test_blue.png"}
    end

    test "iTerm2 includes size parameters", %{test_image: test_image} do
      opts = [width: 200, height: 150, preserve_aspect_ratio: false]
      assert {:ok, rendered} = ImageRenderer.render_with_protocol(test_image, :iterm2, opts)
      
      assert rendered =~ "width=200"
      assert rendered =~ "height=150"  
      assert rendered =~ "preserveAspectRatio=0"
      assert rendered =~ "size="
      assert rendered =~ "inline=1"
    end

    test "iTerm2 preserves aspect ratio by default", %{test_image: test_image} do
      opts = [width: 200]
      assert {:ok, rendered} = ImageRenderer.render_with_protocol(test_image, :iterm2, opts)
      
      # Should not contain preserveAspectRatio since it's not explicitly set
      refute rendered =~ "preserveAspectRatio"
      # But should contain size and inline parameters
      assert rendered =~ "size="
      assert rendered =~ "inline=1"
    end
  end

  # Helper function to set environment variables for tests
  defp with_env(env_vars, fun) do
    original_env = 
      Enum.map(env_vars, fn {key, _value} -> 
        {key, System.get_env(key)}
      end)
    
    try do
      Enum.each(env_vars, fn {key, value} ->
        if value do
          System.put_env(key, value)
        else
          System.delete_env(key)
        end
      end)
      
      fun.()
    after
      Enum.each(original_env, fn {key, value} ->
        if value do
          System.put_env(key, value)
        else
          System.delete_env(key)
        end
      end)
    end
  end
end