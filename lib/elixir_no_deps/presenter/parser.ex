defmodule ElixirNoDeps.Presenter.Parser do
  @moduledoc """
  Parses markdown files into presentations with slides.

  Supports:
  - YAML frontmatter for presentation metadata
  - Slide separation with `---`
  - Title extraction from headings
  - Speaker notes in HTML comments
  """

  alias ElixirNoDeps.Presenter.Presentation
  alias ElixirNoDeps.Presenter.Slide

  @doc """
  Parses a markdown file into a Presentation struct.

  Expected format:
  ```
  ---
  title: "My Presentation"
  author: "John Doe"
  theme: "dark"
  ---

  # First Slide

  Content here

  ---

  # Second Slide

  More content
  ```
  """
  @spec parse_file(String.t()) :: {:ok, Presentation.t()} | {:error, String.t()}
  def parse_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        presentation = parse_content(content, file_path: file_path)
        {:ok, presentation}

      {:error, reason} ->
        {:error, "Failed to read file: #{reason}"}
    end
  end

  @doc """
  Parses markdown content into a Presentation struct.
  """
  @spec parse_content(String.t(), keyword()) :: Presentation.t()
  def parse_content(content, opts \\ []) do
    {metadata, slides_content} = extract_frontmatter(content)
    slides = parse_slides(slides_content)

    presentation_opts =
      metadata
      |> Map.to_list()
      |> Keyword.merge(opts)

    Presentation.new(slides, presentation_opts)
  end

  @doc """
  Extracts YAML frontmatter from the beginning of the content.

  Returns {metadata, remaining_content}
  """
  @spec extract_frontmatter(String.t()) :: {map(), String.t()}
  def extract_frontmatter(content) do
    case String.trim_leading(content) do
      "---" <> _ ->
        # Content starts with frontmatter
        extract_yaml_frontmatter(content)

      _ ->
        # No frontmatter
        {%{}, content}
    end
  end

  @doc """
  Parses slide content separated by `---` into Slide structs.
  """
  @spec parse_slides(String.t()) :: [Slide.t()]
  def parse_slides(content) do
    # Slides are separated by `---` delimiters
    # If there are no `---` delimiters in the content, there are no slides
    slides =
      content
      |> String.split(~r/\n\s*---\s*\n/)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    # If we only got one part and no slide delimiters were found, treat it as no slides
    if length(slides) == 1 and not String.contains?(content, "---") do
      # No slide delimiters found - this is likely just metadata or description text
      []
    else
      # Found slide delimiters, process normally
      slides
      |> Enum.with_index(1)
      |> Enum.map(fn {slide_content, index} ->
        {clean_content, speaker_notes} = extract_speaker_notes(slide_content)
        {final_content, poll_data} = extract_poll_data(clean_content)

        Slide.new(final_content,
          slide_number: index,
          speaker_notes: speaker_notes,
          poll_data: poll_data
        )
      end)
    end
  end

  @doc """
  Extracts speaker notes from HTML comments in slide content.

  Speaker notes format: <!-- Speaker notes: Your notes here -->
  """
  @spec extract_speaker_notes(String.t()) :: {String.t(), String.t() | nil}
  def extract_speaker_notes(content) do
    speaker_notes_regex = ~r/<!--\s*[Ss]peaker\s+[Nn]otes?:\s*(.*?)\s*-->/s

    case Regex.run(speaker_notes_regex, content) do
      [full_match, notes] ->
        clean_content = String.replace(content, full_match, "")
        {String.trim(clean_content), String.trim(notes)}

      nil ->
        {content, nil}
    end
  end

  @doc """
  Extracts poll data from HTML comments in slide content.

  Poll format:
  <!-- poll:
  question: "What's your favorite language?"
  options:
  - Elixir
  - Python
  - JavaScript
  - Rust
  -->
  """
  @spec extract_poll_data(String.t()) :: {String.t(), map() | nil}
  def extract_poll_data(content) do
    poll_regex = ~r/<!--\s*poll:\s*(.*?)\s*-->/s

    case Regex.run(poll_regex, content) do
      [full_match, poll_yaml] ->
        clean_content = String.replace(content, full_match, "")
        poll_data = parse_poll_yaml(poll_yaml)
        {String.trim(clean_content), poll_data}

      nil ->
        {content, nil}
    end
  end

  # Private helper to extract YAML frontmatter
  @spec extract_yaml_frontmatter(String.t()) :: {map(), String.t()}
  defp extract_yaml_frontmatter(content) do
    case Regex.run(~r/^---\s*\n(.*?)\n---\s*\n(.*)$/s, content) do
      [_full, yaml_content, remaining] ->
        metadata = parse_yaml(yaml_content)
        {metadata, remaining}

      nil ->
        {%{}, content}
    end
  end

  # Simple YAML parser for basic key-value pairs
  # Note: This is a minimal implementation for basic frontmatter
  @spec parse_yaml(String.t()) :: map()
  defp parse_yaml(yaml_content) do
    yaml_content
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [key, value] ->
          clean_key = key |> String.trim() |> String.to_atom()
          clean_value = value |> String.trim() |> unquote_string()
          Map.put(acc, clean_key, clean_value)

        _ ->
          acc
      end
    end)
  end

  # Remove quotes from YAML string values
  @spec unquote_string(String.t()) :: String.t()
  defp unquote_string(value) do
    value
    |> String.trim()
    |> String.replace(~r/^["']|["']$/, "")
  end

  # Parse poll YAML data
  @spec parse_poll_yaml(String.t()) :: map() | nil
  defp parse_poll_yaml(poll_yaml) do
    lines = String.split(poll_yaml, "\n") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

    try do
      {question, remaining_lines} = extract_question(lines)
      options = extract_options(remaining_lines)

      if question && length(options) > 0 do
        %{
          question: question,
          options: options,
          type: "multiple_choice"
        }
      else
        nil
      end
    rescue
      _ -> nil
    end
  end

  defp extract_question(lines) do
    case Enum.find_index(lines, &String.starts_with?(&1, "question:")) do
      nil ->
        {nil, lines}

      index ->
        question_line = Enum.at(lines, index)
        question = String.replace(question_line, ~r/^question:\s*/, "") |> String.trim("\"")
        remaining = Enum.drop(lines, index + 1)
        {question, remaining}
    end
  end

  defp extract_options(lines) do
    case Enum.find_index(lines, &(&1 == "options:")) do
      nil ->
        []

      start_index ->
        lines
        |> Enum.drop(start_index + 1)
        |> Enum.take_while(&String.starts_with?(&1, "-"))
        |> Enum.map(&(String.replace(&1, ~r/^-\s*/, "") |> String.trim()))
        |> Enum.reject(&(&1 == ""))
    end
  end
end
