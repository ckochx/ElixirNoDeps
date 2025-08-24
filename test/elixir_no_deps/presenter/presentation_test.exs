defmodule ElixirNoDeps.Presenter.PresentationTest do
  use ExUnit.Case, async: true

  alias ElixirNoDeps.Presenter.Presentation
  alias ElixirNoDeps.Presenter.Slide

  describe "new/2" do
    test "creates empty presentation with defaults" do
      presentation = Presentation.new()

      assert presentation.slides == []
      assert presentation.current_slide == 0
      assert presentation.theme == "default"
      assert presentation.title == nil
      assert presentation.author == nil
    end

    test "creates presentation with slides and metadata" do
      slides = [
        Slide.new("# Slide 1"),
        Slide.new("# Slide 2")
      ]

      opts = [
        title: "My Presentation",
        author: "Test Author",
        theme: "dark"
      ]

      presentation = Presentation.new(slides, opts)

      assert length(presentation.slides) == 2
      assert presentation.title == "My Presentation"
      assert presentation.author == "Test Author"
      assert presentation.theme == "dark"
    end
  end

  describe "navigation" do
    setup do
      slides = [
        Slide.new("# Slide 1"),
        Slide.new("# Slide 2"),
        Slide.new("# Slide 3")
      ]

      presentation = Presentation.new(slides)
      {:ok, presentation: presentation}
    end

    test "current_slide/1 returns first slide initially", %{presentation: presentation} do
      slide = Presentation.current_slide(presentation)
      assert slide.title == "Slide 1"
    end

    test "next_slide/1 advances to next slide", %{presentation: presentation} do
      updated = Presentation.next_slide(presentation)
      slide = Presentation.current_slide(updated)

      assert slide.title == "Slide 2"
      assert updated.current_slide == 1
    end

    test "next_slide/1 stops at last slide", %{presentation: presentation} do
      # Go to last slide
      updated =
        presentation
        |> Presentation.goto_slide(2)
        |> Presentation.next_slide()

      assert updated.current_slide == 2
      slide = Presentation.current_slide(updated)
      assert slide.title == "Slide 3"
    end

    test "prev_slide/1 goes to previous slide", %{presentation: presentation} do
      updated =
        presentation
        |> Presentation.next_slide()
        |> Presentation.prev_slide()

      assert updated.current_slide == 0
      slide = Presentation.current_slide(updated)
      assert slide.title == "Slide 1"
    end

    test "prev_slide/1 stops at first slide", %{presentation: presentation} do
      updated = Presentation.prev_slide(presentation)

      assert updated.current_slide == 0
      slide = Presentation.current_slide(updated)
      assert slide.title == "Slide 1"
    end

    test "goto_slide/2 jumps to specific slide", %{presentation: presentation} do
      updated = Presentation.goto_slide(presentation, 2)
      slide = Presentation.current_slide(updated)

      assert slide.title == "Slide 3"
      assert updated.current_slide == 2
    end

    test "goto_slide/2 clamps to valid range", %{presentation: presentation} do
      # Test negative index
      updated = Presentation.goto_slide(presentation, -1)
      assert updated.current_slide == 0

      # Test too large index
      updated = Presentation.goto_slide(presentation, 10)
      assert updated.current_slide == 2
    end
  end

  describe "helper functions" do
    setup do
      slides = [Slide.new("# Slide 1"), Slide.new("# Slide 2")]
      presentation = Presentation.new(slides)
      {:ok, presentation: presentation}
    end

    test "slide_count/1 returns correct count", %{presentation: presentation} do
      assert Presentation.slide_count(presentation) == 2
    end

    test "current_slide_number/1 returns 1-based index", %{presentation: presentation} do
      assert Presentation.current_slide_number(presentation) == 1

      updated = Presentation.next_slide(presentation)
      assert Presentation.current_slide_number(updated) == 2
    end

    test "has_next?/1 and has_prev?/1 work correctly", %{presentation: presentation} do
      # At first slide
      assert Presentation.has_next?(presentation) == true
      assert Presentation.has_prev?(presentation) == false

      # At last slide
      updated = Presentation.goto_slide(presentation, 1)
      assert Presentation.has_next?(updated) == false
      assert Presentation.has_prev?(updated) == true
    end
  end

  test "current_slide/1 returns nil for empty presentation" do
    presentation = Presentation.new([])
    assert Presentation.current_slide(presentation) == nil
  end
end
