defmodule ElixirNoDeps.Presenter.Input do
  @moduledoc """
  Unified input handler that adapts to different runtime contexts.

  Provides reliable input handling that works in both Mix and escript environments,
  with fallback strategies for different terminal capabilities.
  """

  @doc """
  Gets input using the best available method for the current environment.
  """
  @spec get_input() :: String.t() | atom()
  def get_input do
    if running_as_escript?() do
      get_raw_input()
    else
      get_mix_input()
    end
  end

  @doc """
  Gets input optimized for Mix context with graceful line-based fallback.
  """
  @spec get_mix_input() :: String.t() | atom()
  def get_mix_input do
    case :io.get_line(:standard_io, ~c"") do
      :eof ->
        :quit

      {:error, _} ->
        :quit

      data when is_list(data) ->
        input = List.to_string(data) |> String.trim()
        parse_input(input)

      data when is_binary(data) ->
        input = String.trim(data)
        parse_input(input)
    end
  rescue
    _ -> :quit
  end

  @doc """
  Gets raw character input for escript context.
  """
  @spec get_raw_input() :: String.t() | atom()
  def get_raw_input do
    case get_raw_key() do
      :quit -> :quit
      :ctrl_c -> :quit
      :ctrl_d -> :quit
      key -> key
    end
  end

  @doc """
  Enables raw terminal mode for single character input.
  """
  @spec enable_raw_mode() :: :ok | :error | :not_a_tty
  def enable_raw_mode do
    try do
      case System.cmd("stty", ["raw", "-echo"], stderr_to_stdout: true) do
        {_output, 0} ->
          :ok

        {error, _code} ->
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
  @spec disable_raw_mode() :: :ok | :error | :not_a_tty
  def disable_raw_mode do
    try do
      case System.cmd("stty", ["cooked", "echo"], stderr_to_stdout: true) do
        {_output, 0} ->
          :ok

        {_error, _code} ->
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

      _error ->
        func.()
    end
  end

  @doc """
  Gets terminal dimensions.
  """
  @spec get_terminal_size() :: {pos_integer(), pos_integer()}
  def get_terminal_size do
    case System.cmd("stty", ["size"], stderr_to_stdout: true) do
      {output, 0} ->
        case String.trim(output) |> String.split() do
          [rows, cols] ->
            {String.to_integer(cols), String.to_integer(rows)}

          _ ->
            {80, 24}
        end

      {_error, _code} ->
        {80, 24}
    end
  rescue
    _error ->
      {80, 24}
  end

  # Private functions

  defp parse_input(input) do
    case input do
      "" -> " "  # Enter = advance
      " " -> " "  # Space = advance
      "q" -> :quit
      "Q" -> :quit
      key -> String.at(key, 0)  # First character
    end
  end

  defp get_raw_key do
    case get_raw_char() do
      "\e" ->
        handle_escape_sequence()

      "\x03" -> :ctrl_c  # Ctrl+C
      "\x04" -> :ctrl_d  # Ctrl+D
      "\x1A" -> :ctrl_z  # Ctrl+Z
      "\r" -> :enter
      "\n" -> :enter
      "\t" -> :tab
      "\x7F" -> :backspace
      "\x08" -> :backspace

      char when is_binary(char) -> char
      :eof -> :quit
      :error -> :error
    end
  end

  defp get_raw_char do
    try do
      case IO.getn("", 1) do
        :eof -> :error
        char -> char
      end
    rescue
      _error -> :error
    catch
      _type, _value -> :error
    end
  end

  defp handle_escape_sequence do
    case get_raw_char() do
      "[" -> handle_ansi_sequence()
      "O" -> handle_function_key()
      char when is_binary(char) -> {:alt, char}
      :error -> :escape
    end
  end

  defp handle_ansi_sequence do
    case get_raw_char() do
      "A" -> :arrow_up
      "B" -> :arrow_down
      "C" -> :arrow_right
      "D" -> :arrow_left
      "H" -> :home
      "F" -> :end
      _ -> :unknown
    end
  end

  defp handle_function_key do
    case get_raw_char() do
      "P" -> :f1
      "Q" -> :f2
      "R" -> :f3
      "S" -> :f4
      _ -> :unknown
    end
  end

  defp running_as_escript? do
    case :escript.script_name() do
      :undefined -> false
      _name -> true
    end
  rescue
    _ -> false
  end
end