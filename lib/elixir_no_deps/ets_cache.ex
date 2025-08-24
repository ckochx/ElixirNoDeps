defmodule ElixirNoDeps.ETSCache do
  @moduledoc """
  An ETS cache client impl.
  """

  # 1 hour
  @ttl 3600

  def setup do
    :ets.new(:ets_cache0, [
      # gives us key=>value semantics
      :set,

      # allows any process to read/write to our table
      :public,

      # allow the ETS table to access by it's name, `:myapp_users`
      :named_table,

      # favor read-locks over write-locks
      read_concurrency: true
    ])
  end

  def get(key) do
    entry = :ets.lookup(:ets_cache0, key)

    with [{^key, value, expiry}] <- entry,
         false <- :erlang.system_time(:second) > expiry do
      value
    else
      # key not found in ets
      [] ->
        nil

      true ->
        # key found but past expiry, delete
        :ets.delete(:ets_cache0, key)
        nil
    end
  end

  def put(key, value, ttl \\ @ttl) do
    expires = :erlang.system_time(:second) + ttl
    :ets.insert(:ets_cache0, {key, value, expires})
  end
end
