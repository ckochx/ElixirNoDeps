defmodule ElixirNoDepsTest do
  use ExUnit.Case
  doctest ElixirNoDeps

  test "greets the world" do
    assert ElixirNoDeps.hello() == :world
  end
end
