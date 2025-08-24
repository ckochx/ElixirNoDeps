defmodule ElixirNoDeps.Presenter.SlideTest do
  use ExUnit.Case, async: true

  alias ElixirNoDeps.Presenter.Slide

  describe "new/2" do
    test "creates a slide with basic content" do
      content = "# Hello World\n\nThis is a test slide."
      slide = Slide.new(content)

      assert slide.content == content
      assert slide.raw_content == content
      assert slide.title == "Hello World"
      assert slide.slide_number == 1
      assert is_binary(slide.id)
    end

    test "creates a slide with options" do
      content = "Some content"

      opts = [
        slide_number: 5,
        speaker_notes: "Remember to smile",
        metadata: %{theme: "dark"}
      ]

      slide = Slide.new(content, opts)

      assert slide.slide_number == 5
      assert slide.speaker_notes == "Remember to smile"
      assert slide.metadata == %{theme: "dark"}
    end
  end

  describe "extract_title/1" do
    test "extracts title from heading" do
      content = "# My Title\n\nSome content"
      assert Slide.extract_title(content) == "My Title"
    end

    test "extracts title from multiple hash heading" do
      content = "### Deep Heading\n\nSome content"
      assert Slide.extract_title(content) == "Deep Heading"
    end

    test "returns nil when no heading found" do
      content = "Just some text without heading"
      assert Slide.extract_title(content) == nil
    end

    test "finds first heading when multiple exist" do
      content = "# First Title\n\nContent\n\n## Second Title"
      assert Slide.extract_title(content) == "First Title"
    end
  end

  describe "generate_id/0" do
    test "generates unique IDs" do
      id1 = Slide.generate_id()
      id2 = Slide.generate_id()

      assert is_binary(id1)
      assert is_binary(id2)
      assert id1 != id2
      # 8 bytes * 2 hex chars
      assert String.length(id1) == 16
    end
  end
end
