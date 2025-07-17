# Copied from: git@github.com:papa-whisky/elixir_ascii_image.git
defmodule Mix.Tasks.Asciify do
  @moduledoc """
  A Mix Task to print an ascii-fied image to standard output.
  """
  use Mix.Task

  @shortdoc "Runs the ElixirAsciiImage.asciify/1 function"
  def run(args) do
    ElixirNoDeps.AsciiImage.asciify List.first(args)
  end
end
