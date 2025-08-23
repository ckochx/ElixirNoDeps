defmodule ElixirNoDeps.Presenter.Slide do
  @moduledoc """
  Represents a single slide in a presentation.
  
  A slide contains:
  - Raw markdown content
  - Processed content for display
  - Metadata like title, speaker notes
  - Formatting options
  """

  defstruct [
    :id,
    :title,
    :content,
    :raw_content,
    :speaker_notes,
    :metadata,
    :slide_number
  ]

  @type t :: %__MODULE__{
    id: String.t(),
    title: String.t() | nil,
    content: String.t(),
    raw_content: String.t(),
    speaker_notes: String.t() | nil,
    metadata: map(),
    slide_number: integer()
  }

  @doc """
  Creates a new slide with the given content and metadata.
  """
  @spec new(String.t(), keyword()) :: t()
  def new(content, opts \\ []) do
    id = generate_id()
    slide_number = Keyword.get(opts, :slide_number, 1)
    
    %__MODULE__{
      id: id,
      title: extract_title(content),
      content: content,
      raw_content: content,
      speaker_notes: Keyword.get(opts, :speaker_notes),
      metadata: Keyword.get(opts, :metadata, %{}),
      slide_number: slide_number
    }
  end

  @doc """
  Extracts the title from slide content (first # heading).
  """
  @spec extract_title(String.t()) :: String.t() | nil
  def extract_title(content) do
    content
    |> String.split("\n")
    |> Enum.find(&String.starts_with?(&1, "#"))
    |> case do
      nil -> nil
      title_line -> 
        title_line
        |> String.replace(~r/^#+\s*/, "")
        |> String.trim()
    end
  end

  @doc """
  Generates a unique ID for a slide.
  """
  @spec generate_id() :: String.t()
  def generate_id do
    :crypto.strong_rand_bytes(8)
    |> Base.encode16(case: :lower)
  end
end