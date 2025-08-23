defmodule ElixirNoDeps.Presenter.Presentation do
  @moduledoc """
  Represents a complete presentation containing multiple slides.
  
  Manages:
  - Collection of slides
  - Presentation metadata (title, author, theme)
  - Navigation state (current slide)
  - Configuration options
  """

  alias ElixirNoDeps.Presenter.Slide

  defstruct [
    :title,
    :author,
    :theme,
    :slides,
    :current_slide,
    :file_path,
    :metadata,
    :created_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
    title: String.t() | nil,
    author: String.t() | nil,
    theme: String.t(),
    slides: [Slide.t()],
    current_slide: non_neg_integer(),
    file_path: String.t() | nil,
    metadata: map(),
    created_at: DateTime.t(),
    updated_at: DateTime.t()
  }

  @default_theme "default"

  @doc """
  Creates a new presentation with slides and metadata.
  """
  @spec new([Slide.t()], keyword()) :: t()
  def new(slides \\ [], opts \\ []) do
    now = DateTime.utc_now()
    
    %__MODULE__{
      title: Keyword.get(opts, :title),
      author: Keyword.get(opts, :author),
      theme: Keyword.get(opts, :theme, @default_theme),
      slides: slides,
      current_slide: 0,
      file_path: Keyword.get(opts, :file_path),
      metadata: Keyword.get(opts, :metadata, %{}),
      created_at: now,
      updated_at: now
    }
  end

  @doc """
  Returns the current slide or nil if no slides exist.
  """
  @spec current_slide(t()) :: Slide.t() | nil
  def current_slide(%__MODULE__{slides: [], current_slide: _}), do: nil
  def current_slide(%__MODULE__{slides: slides, current_slide: index}) do
    Enum.at(slides, index)
  end

  @doc """
  Navigates to the next slide. Returns updated presentation.
  """
  @spec next_slide(t()) :: t()
  def next_slide(%__MODULE__{slides: slides, current_slide: current} = presentation) do
    max_index = length(slides) - 1
    new_index = min(current + 1, max_index)
    
    %{presentation | current_slide: new_index, updated_at: DateTime.utc_now()}
  end

  @doc """
  Navigates to the previous slide. Returns updated presentation.
  """
  @spec prev_slide(t()) :: t()
  def prev_slide(%__MODULE__{current_slide: current} = presentation) do
    new_index = max(current - 1, 0)
    
    %{presentation | current_slide: new_index, updated_at: DateTime.utc_now()}
  end

  @doc """
  Jumps to a specific slide by index (0-based). Returns updated presentation.
  """
  @spec goto_slide(t(), non_neg_integer()) :: t()
  def goto_slide(%__MODULE__{slides: slides} = presentation, index) do
    max_index = length(slides) - 1
    new_index = max(0, min(index, max_index))
    
    %{presentation | current_slide: new_index, updated_at: DateTime.utc_now()}
  end

  @doc """
  Returns total number of slides.
  """
  @spec slide_count(t()) :: non_neg_integer()
  def slide_count(%__MODULE__{slides: slides}), do: length(slides)

  @doc """
  Returns current slide number (1-based for display).
  """
  @spec current_slide_number(t()) :: non_neg_integer()
  def current_slide_number(%__MODULE__{current_slide: index}), do: index + 1

  @doc """
  Checks if there is a next slide available.
  """
  @spec has_next?(t()) :: boolean()
  def has_next?(%__MODULE__{slides: slides, current_slide: current}) do
    current < length(slides) - 1
  end

  @doc """
  Checks if there is a previous slide available.
  """
  @spec has_prev?(t()) :: boolean()
  def has_prev?(%__MODULE__{current_slide: current}), do: current > 0
end