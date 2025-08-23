defmodule ElixirNoDeps.Presenter.ParserTest do
  use ExUnit.Case, async: true

  alias ElixirNoDeps.Presenter.{Parser, Presentation, Slide}

  describe "parse_content/2" do
    test "parses simple markdown without frontmatter" do
      content = """
      # First Slide

      This is the first slide

      ---

      # Second Slide

      This is the second slide
      """

      presentation = Parser.parse_content(content)

      assert length(presentation.slides) == 2
      assert presentation.title == nil
      assert presentation.author == nil
      assert presentation.theme == "default"

      [slide1, slide2] = presentation.slides
      assert slide1.title == "First Slide"
      assert slide1.slide_number == 1
      assert slide2.title == "Second Slide"
      assert slide2.slide_number == 2
    end

    test "parses markdown with YAML frontmatter" do
      content = """
      ---
      title: "My Presentation"
      author: "John Doe"
      theme: "dark"
      ---

      # Welcome

      Welcome to my presentation!

      ---

      # Thank You

      Questions?
      """

      presentation = Parser.parse_content(content)

      assert presentation.title == "My Presentation"
      assert presentation.author == "John Doe"
      assert presentation.theme == "dark"
      assert length(presentation.slides) == 2
    end

    test "parses markdown with speaker notes" do
      content = """
      # First Slide

      Public content

      <!-- Speaker notes: Remember to speak slowly -->

      ---

      # Second Slide

      More content
      <!-- Speaker Notes: This is important -->
      """

      presentation = Parser.parse_content(content)
      [slide1, slide2] = presentation.slides

      assert slide1.speaker_notes == "Remember to speak slowly"
      assert slide2.speaker_notes == "This is important"

      # Ensure speaker notes are removed from content
      refute String.contains?(slide1.content, "Speaker notes")
      refute String.contains?(slide2.content, "Speaker Notes")
    end
  end

  describe "extract_frontmatter/1" do
    test "extracts YAML frontmatter correctly" do
      content = """
      ---
      title: "Test Title"
      author: "Test Author"
      ---

      # Content here
      """

      {metadata, remaining} = Parser.extract_frontmatter(content)

      assert metadata[:title] == "Test Title"
      assert metadata[:author] == "Test Author"
      assert String.contains?(remaining, "# Content here")
      refute String.contains?(remaining, "---")
    end

    test "returns empty metadata when no frontmatter" do
      content = """
      # Just content

      No frontmatter here
      """

      {metadata, remaining} = Parser.extract_frontmatter(content)

      assert metadata == %{}
      assert remaining == content
    end

    test "handles quoted values in YAML" do
      content = """
      ---
      title: "Quoted Title"
      author: 'Single Quoted'
      theme: unquoted
      ---

      Content
      """

      {metadata, _} = Parser.extract_frontmatter(content)

      assert metadata[:title] == "Quoted Title"
      assert metadata[:author] == "Single Quoted"
      assert metadata[:theme] == "unquoted"
    end
  end

  describe "parse_slides/1" do
    test "splits content into slides by ---" do
      content = """
      # Slide One
      Content 1

      ---

      # Slide Two
      Content 2

      ---

      # Slide Three
      Content 3
      """

      slides = Parser.parse_slides(content)

      assert length(slides) == 3
      assert Enum.at(slides, 0).title == "Slide One"
      assert Enum.at(slides, 1).title == "Slide Two"
      assert Enum.at(slides, 2).title == "Slide Three"

      # Check slide numbers
      assert Enum.at(slides, 0).slide_number == 1
      assert Enum.at(slides, 1).slide_number == 2
      assert Enum.at(slides, 2).slide_number == 3
    end

    test "handles slides with whitespace around separators" do
      content = """
      # First Slide

      ---

      # Second Slide

        ---   

      # Third Slide
      """

      slides = Parser.parse_slides(content)

      assert length(slides) == 3
      assert Enum.all?(slides, &is_struct(&1, Slide))
    end

    test "ignores empty slides" do
      content = """
      # Real Slide

      ---

      ---

      # Another Real Slide
      """

      slides = Parser.parse_slides(content)

      assert length(slides) == 2
      assert Enum.at(slides, 0).title == "Real Slide"
      assert Enum.at(slides, 1).title == "Another Real Slide"
    end
  end

  describe "extract_speaker_notes/1" do
    test "extracts speaker notes from HTML comments" do
      content = """
      # Slide Title

      Main content here

      <!-- Speaker notes: Don't forget the demo -->
      """

      {clean_content, notes} = Parser.extract_speaker_notes(content)

      assert notes == "Don't forget the demo"
      refute String.contains?(clean_content, "Speaker notes")
      assert String.contains?(clean_content, "Main content here")
    end

    test "handles different capitalization" do
      content = "Content <!-- speaker Notes: test -->"

      {_clean, notes} = Parser.extract_speaker_notes(content)

      assert notes == "test"
    end

    test "returns nil when no speaker notes" do
      content = """
      # Regular slide

      Just normal content
      """

      {clean_content, notes} = Parser.extract_speaker_notes(content)

      assert notes == nil
      assert clean_content == content
    end

    test "handles multiline speaker notes" do
      content = """
      # Slide

      <!-- Speaker notes: 
           This is a multiline note
           with multiple lines -->
      """

      {_clean, notes} = Parser.extract_speaker_notes(content)

      assert String.contains?(notes, "multiline note")
      assert String.contains?(notes, "multiple lines")
    end
  end
end
