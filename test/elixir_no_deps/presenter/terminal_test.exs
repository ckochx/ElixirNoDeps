defmodule ElixirNoDeps.Presenter.TerminalTest do
  use ExUnit.Case, async: true

  alias ElixirNoDeps.Presenter.Terminal

  describe "colorize/2" do
    test "applies color codes to text" do
      result = Terminal.colorize("hello", :red)
      assert String.contains?(result, "\e[31m")
      assert String.contains?(result, "hello")
      assert String.ends_with?(result, "\e[0m")
    end

    test "returns original text for unknown colors" do
      result = Terminal.colorize("hello", :unknown_color)
      assert result == "hello"
    end
  end

  describe "format_text/2" do
    test "applies formatting to text" do
      result = Terminal.format_text("hello", :bold)
      assert String.contains?(result, "\e[1m")
      assert String.contains?(result, "hello")
      assert String.ends_with?(result, "\e[0m")
    end

    test "returns original text for unknown formats" do
      result = Terminal.format_text("hello", :unknown_format)
      assert result == "hello"
    end
  end

  describe "style_text/3" do
    test "applies both color and format" do
      result = Terminal.style_text("hello", :red, :bold)
      assert String.contains?(result, "\e[31m")
      assert String.contains?(result, "\e[1m")
      assert String.contains?(result, "hello")
    end

    test "works with only color" do
      result = Terminal.style_text("hello", :blue, nil)
      assert String.contains?(result, "\e[34m")
      assert String.contains?(result, "hello")
    end

    test "works with only format" do
      result = Terminal.style_text("hello", nil, :italic)
      assert String.contains?(result, "\e[3m")
      assert String.contains?(result, "hello")
    end
  end

  describe "center_text/2" do
    test "centers text within given width" do
      result = Terminal.center_text("hello", 10)
      # "hello" is 5 chars, so with width 10, should have 2-3 spaces padding
      assert String.starts_with?(result, "  ")
      assert String.contains?(result, "hello")
    end

    test "returns original text if already too wide" do
      result = Terminal.center_text("very long text", 5)
      assert result == "very long text"
    end

    test "handles empty text" do
      result = Terminal.center_text("", 10)
      # Half of 10
      assert String.length(result) == 5
    end
  end

  describe "wrap_text/2" do
    test "wraps long lines to specified width" do
      text = "This is a very long line that should be wrapped"
      result = Terminal.wrap_text(text, 20)

      assert is_list(result)
      assert length(result) > 1
      assert Enum.all?(result, &(Terminal.visible_length(&1) <= 20))
    end

    test "preserves existing line breaks" do
      text = "Line 1\nLine 2\nLine 3"
      result = Terminal.wrap_text(text, 50)

      assert length(result) == 3
      assert Enum.at(result, 0) == "Line 1"
      assert Enum.at(result, 1) == "Line 2"
      assert Enum.at(result, 2) == "Line 3"
    end

    test "handles empty text" do
      result = Terminal.wrap_text("", 10)
      assert result == [""]
    end
  end

  describe "visible_length/1" do
    test "calculates length excluding ANSI codes" do
      text_with_ansi = "\e[31mhello\e[0m world"
      result = Terminal.visible_length(text_with_ansi)
      # "hello world"
      assert result == 11
    end

    test "handles text without ANSI codes" do
      result = Terminal.visible_length("hello world")
      assert result == 11
    end

    test "handles empty string" do
      result = Terminal.visible_length("")
      assert result == 0
    end
  end

  describe "horizontal_line/2" do
    test "creates line with default character" do
      result = Terminal.horizontal_line(10)
      assert result == "----------"
    end

    test "creates line with custom character" do
      result = Terminal.horizontal_line("=", 5)
      assert result == "====="
    end
  end

  describe "create_box/2" do
    test "creates box around single line text" do
      result = Terminal.create_box("hello")

      assert length(result) == 3
      assert String.starts_with?(List.first(result), "┌")
      assert String.starts_with?(List.last(result), "└")
      assert String.contains?(Enum.at(result, 1), "│ hello │")
    end

    test "creates box around multi-line text" do
      result = Terminal.create_box("line1\nline2")

      # top + 2 content lines + bottom
      assert length(result) == 4
      assert String.starts_with?(List.first(result), "┌")
      assert String.starts_with?(List.last(result), "└")
    end

    test "handles empty text" do
      result = Terminal.create_box("")

      assert length(result) == 3
      assert String.contains?(Enum.at(result, 1), "│  │")
    end
  end
end
