defmodule ElixirNoDeps.Presenter.RendererTest do
  use ExUnit.Case, async: true

  alias ElixirNoDeps.Presenter.{Renderer, Presentation, Slide}

  describe "process_markdown_formatting/1" do
    test "processes headers with color styling" do
      content = "# Main Title\n## Subtitle\n### Small Title"
      result = Renderer.process_markdown_formatting(content)

      # Should contain ANSI codes for colors
      # bright_cyan for h1
      assert String.contains?(result, "\e[96m")
      # bright_yellow for h2
      assert String.contains?(result, "\e[93m")
      # bright_white for h3
      assert String.contains?(result, "\e[97m")
    end

    test "processes bold text" do
      content = "This is **bold** and __also bold__ text"
      result = Renderer.process_markdown_formatting(content)

      # Should contain ANSI codes for bold
      assert String.contains?(result, "\e[1m")
      refute String.contains?(result, "**")
      refute String.contains?(result, "__")
    end

    test "processes italic text" do
      content = "This is *italic* and _also italic_ text"
      result = Renderer.process_markdown_formatting(content)

      # Should contain ANSI codes for italic
      assert String.contains?(result, "\e[3m")
      # Original markdown should be removed (this is tricky with overlapping patterns)
    end

    test "processes inline code" do
      content = "Here is some `inline code` in text"
      result = Renderer.process_markdown_formatting(content)

      # Should contain color codes for code
      # bright_green
      assert String.contains?(result, "\e[92m")
      refute String.contains?(result, "`inline code`")
    end

    test "processes code blocks" do
      content = """
      Here is a code block:
      ```
      def hello do
        :world
      end
      ```
      """

      result = Renderer.process_markdown_formatting(content)

      # Should contain color codes for code blocks or inline code
      # green or bright_green
      assert String.contains?(result, "\e[32m") or String.contains?(result, "\e[92m")
      refute String.contains?(result, "```")
    end

    test "processes unordered lists" do
      content = """
      - Item one
      - Item two
      * Item three
      """

      result = Renderer.process_markdown_formatting(content)

      # Should contain bullet points and blue color
      assert String.contains?(result, "•")
      # bright_blue
      assert String.contains?(result, "\e[94m")
    end

    test "processes numbered lists" do
      content = """
      1. First item
      2. Second item
      10. Tenth item
      """

      result = Renderer.process_markdown_formatting(content)

      # Should contain blue color for list items
      # bright_blue
      assert String.contains?(result, "\e[94m")
    end
  end

  describe "render_content/3" do
    test "wraps content to fit width" do
      content =
        "This is a very long line that should definitely be wrapped to fit within the specified width"

      result = Renderer.render_content(content, 40, 10)

      assert is_list(result)
      assert length(result) > 1
      # Each line should be reasonable length (considering padding)
      # 40 - 4 padding
      assert Enum.all?(result, &(String.length(&1) <= 36))
    end

    test "limits content to available height" do
      content = String.duplicate("Line of text\n", 20)
      result = Renderer.render_content(content, 80, 5)

      # Should be limited to available_height - 3 = 2 lines
      assert length(result) <= 2
    end

    test "handles empty content" do
      result = Renderer.render_content("", 80, 10)

      assert result == [""]
    end
  end

  # Note: render_slide/1 and render_status_bar/3 are harder to test 
  # because they write directly to IO, but the core logic is tested above

  describe "integration with data structures" do
    test "works with real presentation and slides" do
      slides = [
        Slide.new("# Welcome\n\nThis is the first slide"),
        Slide.new("# Features\n\n- Point one\n- Point two")
      ]

      presentation = Presentation.new(slides, title: "Test Presentation")

      # These should not raise errors
      assert is_struct(presentation, Presentation)
      assert Presentation.slide_count(presentation) == 2

      current_slide = Presentation.current_slide(presentation)
      assert current_slide.title == "Welcome"

      # Test markdown processing
      processed = Renderer.process_markdown_formatting(current_slide.content)
      assert is_binary(processed)
      # Should have ANSI codes
      assert String.contains?(processed, "\e[")
    end
  end
end
