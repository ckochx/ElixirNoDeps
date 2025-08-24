defmodule ElixirNoDeps.Server do
  @moduledoc """
  Genserver impl to handle async Cache puts.
  """

  use GenServer, restart: :transient, shutdown: 10_000

  def start_link(state_opts \\ []) do
    inital_state = %{}
    state = Keyword.get(state_opts, :state, inital_state)
    name = Keyword.get(state_opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @impl true
  def init(state \\ []) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:put, {_key, _element, _opts}}, state) do
    # do something Async
    # maybe update the state? 
    {_count, new_state} =
      state
      |> Map.put(:current_time, System.system_time())
      |> Map.get_and_update(:counter, fn count ->
        {count, %{counter: count + 1}}
      end)

    {:noreply, new_state}
  end

  @impl true
  def handle_call({:put, {_key, _element, _opts}}, _from, state) do
    # do something sync
    {count, new_state} =
      state
      |> Map.put(:current_time, System.system_time())
      |> Map.get_and_update(:counter, fn count ->
        {count, %{counter: count + 1}}
      end)

    {:reply, count, new_state}
  end

  def cast(key, element, opts) do
    GenServer.cast(__MODULE__, {:put, {key, element, opts}})
  end

  def call(key, element, opts) do
    GenServer.call(__MODULE__, {:put, {key, element, opts}})
  end
end
