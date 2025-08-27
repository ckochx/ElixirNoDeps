# Copied from: git@github.com:papa-whisky/elixir_ascii_image.git
defmodule ElixirNoDeps.AsciiImage do
  @moduledoc """
  Documentation for ElixirAsciiImage.
  """
  @ascii_list "$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\\|()1{}[]?-_+~i!lI;:,\"^`"

  @doc """
  Asciify an image

  ## Examples

      iex> ElixirAsciiImage.asciify(img_path)
      # => Prints ASCII-ified version of image at img_path to standard output
      :ok

  """
  def asciify(img_path) do
    ascii_matrix = ascii_matrix(img_path)

    ascii_matrix
    |> Enum.map(&Enum.join/1)
    |> Enum.map(&IO.puts/1)
  end

  defp ascii_matrix(img_path) do
    {raw_pixel_data, 0} = System.cmd("magick", ["-display", "none", img_path, "-resize", "250", "sparse-color:"])

    raw_pixel_data
    |> String.split()
    |> Enum.map(&String.split(&1, ",", parts: 3))
    |> Enum.reduce([], &pixels_to_rows/2)
    |> Enum.map(&row_rgb_values/1)
    |> Enum.map(&row_brightness_values/1)
    |> Enum.map(&row_ascii_characters/1)
  end

  defp pixels_to_rows(pixel, acc) do
    row = pixel |> Enum.at(1) |> String.to_integer()

    acc =
      if Enum.at(acc, row) == nil do
        acc ++ [[]]
      else
        acc
      end

    acc |> List.replace_at(row, Enum.at(acc, row) ++ [pixel])
  end

  defp row_rgb_values(row) do
    row |> Enum.map(&pixel_rgb_value/1)
  end

  defp pixel_rgb_value(pixel) do
    pixel
    |> Enum.at(-1)
    |> String.slice(5..-2//1)
    |> String.split(",")
    |> Enum.map(&parse_percentage_to_rgb/1)
  end

  defp parse_percentage_to_rgb(percentage_str) do
    cleaned = String.replace(percentage_str, "%", "")

    # Handle both integer and float strings
    value =
      if String.contains?(cleaned, ".") do
        String.to_float(cleaned)
      else
        String.to_integer(cleaned) |> Kernel./(1.0)
      end

    (value * 255 / 100) |> round()
  end

  defp row_brightness_values(row) do
    row
    |> Enum.map(&(Enum.sum(&1) / 3))
    |> Enum.map(&round/1)
  end

  defp row_ascii_characters(row) do
    row |> Enum.map(&brightness_to_ascii/1)
  end

  defp brightness_to_ascii(value) do
    fraction = value / 255
    character_index = round(65 * fraction) - 1
    character = String.slice(@ascii_list, character_index, 1)
    Enum.join([character, character, character])
  end
end
