defmodule ElixirNoDeps.PollStorage do
  @moduledoc """
  ETS-based storage for poll responses and results.

  Stores vote data in memory for fast access and real-time updates.
  Data structure: {slide_id, option_index, vote_count}
  """

  @table_name :poll_votes

  @doc """
  Starts the ETS table for poll storage.
  """
  def start_link do
    :ets.new(@table_name, [:named_table, :public, :set])
    {:ok, @table_name}
  end

  @doc """
  Records a vote for a poll option.
  """
  @spec vote(String.t(), integer()) :: :ok
  def vote(slide_id, option_index) do
    key = {slide_id, option_index}

    case :ets.lookup(@table_name, key) do
      [{^key, _count}] ->
        :ets.update_counter(@table_name, key, 1)

      [] ->
        :ets.insert(@table_name, {key, 1})
    end

    :ok
  end

  @doc """
  Gets vote results for a specific poll slide.
  """
  @spec get_results(String.t()) :: map()
  def get_results(slide_id) do
    pattern = {{slide_id, :"$1"}, :"$2"}

    :ets.match(@table_name, pattern)
    |> Enum.reduce(%{}, fn [option_index, count], acc ->
      Map.put(acc, option_index, count)
    end)
  end

  @doc """
  Gets total vote count for a poll.
  """
  @spec get_total_votes(String.t()) :: integer()
  def get_total_votes(slide_id) do
    slide_id
    |> get_results()
    |> Map.values()
    |> Enum.sum()
  end

  @doc """
  Clears all votes for a specific poll.
  """
  @spec clear_poll(String.t()) :: :ok
  def clear_poll(slide_id) do
    pattern = {{slide_id, :"$1"}, :_}
    keys = :ets.match(@table_name, pattern) |> Enum.map(&List.first/1)

    Enum.each(keys, fn option_index ->
      :ets.delete(@table_name, {slide_id, option_index})
    end)

    :ok
  end

  @doc """
  Clears all poll data.
  """
  @spec clear_all() :: :ok
  def clear_all do
    :ets.delete_all_objects(@table_name)
    :ok
  end
end
