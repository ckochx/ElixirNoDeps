defmodule ElixirNoDeps.Presenter.SimpleInput do
  @moduledoc """
  Simplified input handler that works within Mix's constraints.
  
  Since Mix redirects stdin through sockets (not TTY), traditional
  stty raw mode doesn't work. This module provides a workable
  alternative that captures input character by character when possible.
  """

  @doc """
  Gets a single character input, trying to minimize the need for Enter.
  """
  @spec get_key() :: String.t() | atom()
  def get_key do
    # In Mix context, we still need to use IO.getn but we can make it work better
    try do
      case IO.getn("", 1) do
        :eof -> :quit
        "\n" -> :enter  # Enter key
        "\r" -> :enter  # Return key  
        "\x03" -> :quit # Ctrl+C
        "\x04" -> :quit # Ctrl+D
        "\e" -> handle_escape_sequence()
        char when is_binary(char) -> char
        _ -> :unknown
      end
    rescue
      _ -> :error
    end
  end

  @doc """
  Get input with a simple prompt that guides the user.
  """
  @spec get_key_with_prompt() :: String.t() | atom()
  def get_key_with_prompt do
    # Use :io.get_chars which works better in Mix context
    IO.write("Press any key (space=next, q=quit): ")
    
    case :io.get_chars(~c"", 1) do
      :eof -> :quit
      [char] when is_integer(char) -> 
        # Convert the character code to string
        <<char::utf8>>
      char when is_list(char) and length(char) == 1 ->
        # Handle single character list
        List.to_string(char)
      _ -> :unknown
    end
  rescue
    _ -> :quit
  end

  @doc """
  A hybrid approach - tries to be smart about when to show prompts.
  """
  @spec get_smart_input() :: String.t() | atom()
  def get_smart_input do
    # Simple, reliable input that works in both Mix and escript
    case :io.get_line(:standard_io, ~c"") do
      :eof -> :quit
      {:error, _} -> :quit
      data when is_list(data) ->
        input = List.to_string(data) |> String.trim()
        case input do
          "" -> " "  # Just Enter = advance
          " " -> " " # Space + Enter = advance  
          "q" -> :quit
          "Q" -> :quit
          key -> String.at(key, 0)  # First character
        end
      data when is_binary(data) ->
        input = String.trim(data)
        case input do
          "" -> " "  # Just Enter = advance
          " " -> " " # Space + Enter = advance
          "q" -> :quit
          "Q" -> :quit
          key -> String.at(key, 0)
        end
    end
  rescue
    _ -> :quit
  end


  # Private functions

  defp handle_escape_sequence do
    # Try to read the escape sequence
    case IO.getn("", 1) do
      "[" ->
        case IO.getn("", 1) do
          "A" -> :arrow_up
          "B" -> :arrow_down
          "C" -> :arrow_right
          "D" -> :arrow_left
          _ -> :unknown
        end
      _ -> :escape
    end
  rescue
    _ -> :escape
  end
end