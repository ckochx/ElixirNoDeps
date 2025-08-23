defmodule ElixirNoDeps.Presenter.Terminal do
  @moduledoc """
  Terminal rendering utilities for presentations.
  
  Handles:
  - Screen clearing and positioning
  - ANSI color and formatting codes
  - Text centering and wrapping
  - Status bar rendering
  """

  # ANSI escape codes for terminal control.
  @clear_screen "\e[2J"
  @move_cursor_home "\e[H"
  @hide_cursor "\e[?25l"
  @show_cursor "\e[?25h"
  # @save_cursor "\e[s"
  # @restore_cursor "\e[u"

  # ANSI color codes.
  @colors %{
    black: 30,
    red: 31,
    green: 32,
    yellow: 33,
    blue: 34,
    magenta: 35,
    cyan: 36,
    white: 37,
    bright_black: 90,
    bright_red: 91,
    bright_green: 92,
    bright_yellow: 93,
    bright_blue: 94,
    bright_magenta: 95,
    bright_cyan: 96,
    bright_white: 97
  }

  # ANSI formatting codes.
  @formats %{
    reset: 0,
    bold: 1,
    dim: 2,
    italic: 3,
    underline: 4,
    blink: 5,
    reverse: 7,
    strikethrough: 9
  }

  @doc """
  Clears the terminal screen and moves cursor to home position.
  """
  @spec clear_screen() :: :ok
  def clear_screen do
    IO.write(@clear_screen <> @move_cursor_home)
    :ok
  end

  @doc """
  Hides the terminal cursor.
  """
  @spec hide_cursor() :: :ok
  def hide_cursor do
    IO.write(@hide_cursor)
    :ok
  end

  @doc """
  Shows the terminal cursor.
  """
  @spec show_cursor() :: :ok
  def show_cursor do
    IO.write(@show_cursor)
    :ok
  end

  @doc """
  Gets terminal dimensions as {width, height}.
  Falls back to 80x24 if unable to determine.
  """
  @spec get_dimensions() :: {pos_integer(), pos_integer()}
  def get_dimensions do
    case :io.columns() do
      {:ok, cols} ->
        rows = case :io.rows() do
          {:ok, r} -> r
          _ -> 24
        end
        {cols, rows}
      _ ->
        {80, 24}
    end
  end

  @doc """
  Applies ANSI color to text.
  """
  @spec colorize(String.t(), atom()) :: String.t()
  def colorize(text, color) when is_atom(color) do
    case Map.get(@colors, color) do
      nil -> text
      code -> "\e[#{code}m#{text}\e[0m"
    end
  end

  @doc """
  Applies ANSI formatting to text.
  """
  @spec format_text(String.t(), atom()) :: String.t()
  def format_text(text, format) when is_atom(format) do
    case Map.get(@formats, format) do
      nil -> text
      code -> "\e[#{code}m#{text}\e[0m"
    end
  end

  @doc """
  Combines color and format for text.
  """
  @spec style_text(String.t(), atom() | nil, atom() | nil) :: String.t()
  def style_text(text, color \\ nil, format \\ nil) do
    text
    |> apply_color(color)
    |> apply_format(format)
  end

  @doc """
  Centers text within the given width.
  """
  @spec center_text(String.t(), pos_integer()) :: String.t()
  def center_text(text, width) do
    text_width = visible_length(text)
    
    if text_width >= width do
      text
    else
      padding = div(width - text_width, 2)
      String.duplicate(" ", padding) <> text
    end
  end

  @doc """
  Wraps text to fit within the specified width.
  """
  @spec wrap_text(String.t(), pos_integer()) :: [String.t()]
  def wrap_text(text, width) do
    text
    |> String.split("\n")
    |> Enum.flat_map(&wrap_line(&1, width))
  end

  @doc """
  Calculates the visible length of text (excluding ANSI codes).
  """
  @spec visible_length(String.t()) :: non_neg_integer()
  def visible_length(text) do
    text
    |> String.replace(~r/\e\[[0-9;]*m/, "")
    |> String.length()
  end

  @doc """
  Moves cursor to specific position (1-indexed).
  """
  @spec move_cursor(pos_integer(), pos_integer()) :: :ok
  def move_cursor(row, col) do
    IO.write("\e[#{row};#{col}H")
    :ok
  end

  @doc """
  Prints text at a specific position.
  """
  @spec print_at(pos_integer(), pos_integer(), String.t()) :: :ok
  def print_at(row, col, text) do
    move_cursor(row, col)
    IO.write(text)
    :ok
  end

  @doc """
  Creates a horizontal line of the specified character.
  """
  @spec horizontal_line(String.t(), pos_integer()) :: String.t()
  def horizontal_line(char \\ "-", width) do
    String.duplicate(char, width)
  end

  @doc """
  Creates a box around text with the specified border character.
  """
  @spec create_box(String.t(), String.t()) :: [String.t()]
  def create_box(content, border_char \\ "─") do
    lines = String.split(content, "\n")
    max_width = lines |> Enum.map(&visible_length/1) |> Enum.max()
    
    top_line = "┌" <> String.duplicate(border_char, max_width + 2) <> "┐"
    bottom_line = "└" <> String.duplicate(border_char, max_width + 2) <> "┘"
    
    content_lines = Enum.map(lines, fn line ->
      padding = max_width - visible_length(line)
      "│ " <> line <> String.duplicate(" ", padding) <> " │"
    end)
    
    [top_line] ++ content_lines ++ [bottom_line]
  end

  # Private helper functions

  defp apply_color(text, nil), do: text
  defp apply_color(text, color), do: colorize(text, color)

  defp apply_format(text, nil), do: text
  defp apply_format(text, format), do: format_text(text, format)

  defp wrap_line("", _width), do: [""]
  defp wrap_line(line, width) do
    if visible_length(line) <= width do
      [line]
    else
      # Simple word wrapping - can be enhanced later
      words = String.split(line, " ")
      wrap_words(words, width, "", [])
    end
  end

  defp wrap_words([], _width, "", acc), do: Enum.reverse(acc)
  defp wrap_words([], _width, current_line, acc) do
    Enum.reverse([String.trim(current_line) | acc])
  end
  
  defp wrap_words([word | rest], width, current_line, acc) do
    test_line = if current_line == "", do: word, else: current_line <> " " <> word
    
    if visible_length(test_line) <= width do
      wrap_words(rest, width, test_line, acc)
    else
      if current_line == "" do
        # Word is longer than width, just add it
        wrap_words(rest, width, "", [word | acc])
      else
        # Start new line with current word
        wrap_words(rest, width, word, [String.trim(current_line) | acc])
      end
    end
  end
end