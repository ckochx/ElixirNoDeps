defmodule ElixirNoDeps.Presenter.RawInput do
  @moduledoc """
  Raw keyboard input handling for terminal presentations.

  Provides single-key input without requiring Enter key presses.
  Handles terminal mode switching for better user experience.
  """

  @doc """
  Puts the terminal in raw mode and captures a single character.
  Returns the character without waiting for Enter.
  """
  @spec get_raw_char() :: String.t() | :error
  def get_raw_char do
    # Don't repeatedly enable/disable raw mode - assume it's already enabled
    try do
      # Read a single character - in raw mode this doesn't wait for Enter
      case IO.getn("", 1) do
        :eof -> :error
        char -> char
      end
    rescue
      _error ->
        :error
    catch
      _type, _value ->
        :error
    end
  end

  @doc """
  Reads a raw key with escape sequence handling for arrow keys.
  Returns atoms for special keys or strings for regular characters.
  """
  @spec get_raw_key() :: atom() | String.t()
  def get_raw_key do
    case get_raw_char() do
      "\e" ->
        # Handle escape sequences (arrow keys, function keys, etc.)
        handle_escape_sequence()

      # Control characters
      # Ctrl+C
      "\x03" ->
        :ctrl_c

      # Ctrl+D  
      "\x04" ->
        :ctrl_d

      # Ctrl+Z
      "\x1A" ->
        :ctrl_z

      # Enter/Return
      "\r" ->
        :enter

      # Newline
      "\n" ->
        :enter

      # Tab
      "\t" ->
        :tab

      # Backspace
      "\x7F" ->
        :backspace

      # Alternate backspace
      "\x08" ->
        :backspace

      # Regular character
      char when is_binary(char) ->
        char

      # Handle end of file
      :eof ->
        :error

      # Error case
      :error ->
        :error
    end
  end

  @doc """
  Enables raw terminal mode for single character input.
  """
  @spec enable_raw_mode() :: :ok | :error
  def enable_raw_mode do
    # Try a more targeted approach - focus on what we need
    try do
      # First try the minimal stty command needed
      case System.cmd("stty", ["raw", "-echo"], stderr_to_stdout: true) do
        {_output, 0} ->
          :ok

        {error, _code} ->
          # If raw mode fails, try -icanon instead
          case System.cmd("stty", ["-icanon", "-echo"], stderr_to_stdout: true) do
            {_output, 0} ->
              :ok

            {_error, _code} ->
              if String.contains?(error, "not a tty") or
                   String.contains?(error, "inappropriate ioctl") do
                :not_a_tty
              else
                :error
              end
          end
      end
    rescue
      _error -> :error
    end
  end

  @doc """
  Disables raw terminal mode and restores normal input.
  """
  @spec disable_raw_mode() :: :ok | :error
  def disable_raw_mode do
    try do
      # Try to restore with cooked mode first
      case System.cmd("stty", ["cooked", "echo"], stderr_to_stdout: true) do
        {_output, 0} ->
          :ok

        {_error, _code} ->
          # If cooked fails, try icanon
          case System.cmd("stty", ["icanon", "echo"], stderr_to_stdout: true) do
            {_output, 0} ->
              :ok

            {error, _code} ->
              if String.contains?(error, "not a tty") or
                   String.contains?(error, "inappropriate ioctl") do
                :not_a_tty
              else
                :error
              end
          end
      end
    rescue
      _error -> :error
    end
  end

  @doc """
  Safely wraps a function call with raw mode handling.
  Ensures terminal is properly restored even if the function fails.
  """
  @spec with_raw_mode((-> any())) :: any()
  def with_raw_mode(func) when is_function(func, 0) do
    case enable_raw_mode() do
      :ok ->
        try do
          result = func.()
          disable_raw_mode()
          result
        rescue
          error ->
            disable_raw_mode()
            reraise error, __STACKTRACE__
        catch
          type, value ->
            disable_raw_mode()
            :erlang.raise(type, value, __STACKTRACE__)
        end

      :error ->
        # Run function without raw mode if it fails
        func.()
    end
  end

  @doc """
  Gets terminal dimensions in raw mode (alternative implementation).
  """
  @spec get_terminal_size() :: {pos_integer(), pos_integer()}
  def get_terminal_size do
    case System.cmd("stty", ["size"], stderr_to_stdout: true) do
      {output, 0} ->
        case String.trim(output) |> String.split() do
          [rows, cols] ->
            {String.to_integer(cols), String.to_integer(rows)}

          _ ->
            # Default fallback
            {80, 24}
        end

      {_error, _code} ->
        # Default fallback
        {80, 24}
    end
  rescue
    _error ->
      {80, 24}
  end

  # Private functions

  defp handle_escape_sequence do
    case get_raw_char() do
      "[" ->
        # ANSI escape sequence
        handle_ansi_sequence()

      "O" ->
        # Alternative function key format
        handle_function_key()

      char when is_binary(char) ->
        # Some other escape sequence, treat as alt+key
        {:alt, char}

      :error ->
        :escape
    end
  end

  defp handle_ansi_sequence do
    case get_raw_char() do
      "A" ->
        :arrow_up

      "B" ->
        :arrow_down

      "C" ->
        :arrow_right

      "D" ->
        :arrow_left

      # Home/End/Insert/Delete/Page Up/Page Down
      "H" ->
        :home

      "F" ->
        :end

      "2" ->
        read_extended_key("~", :insert)

      "3" ->
        read_extended_key("~", :delete)

      "5" ->
        read_extended_key("~", :page_up)

      "6" ->
        read_extended_key("~", :page_down)

      # Function keys F1-F12
      "1" ->
        handle_f1_to_f4()

      "2" ->
        handle_f5_to_f8()

      "3" ->
        handle_f9_to_f12()

      # Extended sequences that end with letters
      char when is_binary(char) and byte_size(char) == 1 ->
        case char do
          letter when letter >= "A" and letter <= "Z" ->
            {:extended, letter}

          digit when digit >= "0" and digit <= "9" ->
            read_multi_char_sequence(digit)

          _ ->
            :unknown
        end

      :error ->
        :escape
    end
  end

  defp handle_function_key do
    case get_raw_char() do
      "P" -> :f1
      "Q" -> :f2
      "R" -> :f3
      "S" -> :f4
      char -> {:function, char}
    end
  end

  defp read_extended_key(terminator, key) do
    case get_raw_char() do
      ^terminator -> key
      _other -> :unknown
    end
  end

  defp handle_f1_to_f4 do
    case get_raw_char() do
      "1" -> read_extended_key("~", :f1)
      "2" -> read_extended_key("~", :f2)
      "3" -> read_extended_key("~", :f3)
      "4" -> read_extended_key("~", :f4)
      "5" -> read_extended_key("~", :f5)
      _ -> :unknown
    end
  end

  defp handle_f5_to_f8 do
    case get_raw_char() do
      "0" -> read_extended_key("~", :f9)
      "1" -> read_extended_key("~", :f10)
      "3" -> read_extended_key("~", :f11)
      "4" -> read_extended_key("~", :f12)
      _ -> :unknown
    end
  end

  defp handle_f9_to_f12 do
    # These are handled in handle_f5_to_f8 for most terminals
    :unknown
  end

  defp read_multi_char_sequence(first_char) do
    # Read additional characters until we find a terminator
    # This handles complex escape sequences
    sequence = read_until_terminator([first_char])
    {:sequence, sequence}
  end

  defp read_until_terminator(acc) do
    case get_raw_char() do
      char when char in ["~", "A", "B", "C", "D", "H", "F", "P", "Q", "R", "S"] ->
        # Terminator found
        Enum.reverse([char | acc]) |> Enum.join()

      char when is_binary(char) and byte_size(char) == 1 ->
        # Continue reading
        read_until_terminator([char | acc])

      :error ->
        # End of sequence
        Enum.reverse(acc) |> Enum.join()
    end
  end
end
