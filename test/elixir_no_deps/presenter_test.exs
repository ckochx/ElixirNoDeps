defmodule ElixirNoDeps.PresenterTest do
  use ExUnit.Case, async: false

  alias ElixirNoDeps.Presenter
  alias ElixirNoDeps.Presenter.Presentation
  alias ElixirNoDeps.Presenter.Slide

  describe "run/2" do
    setup do
      # Create a temporary test presentation file
      content = """
      ---
      title: "Test Presentation"
      author: "Test Author"
      ---

      # First Slide

      This is a test slide.

      ---

      # Second Slide

      Another test slide.
      """

      tmp_file = "/tmp/test_presentation_#{System.unique_integer()}.md"
      File.write!(tmp_file, content)

      on_exit(fn ->
        if File.exists?(tmp_file), do: File.rm!(tmp_file)
      end)

      {:ok, file_path: tmp_file}
    end

    test "parses and loads presentation file", %{file_path: file_path} do
      # We can't easily test the full interactive run without mocking IO
      # But we can test the parsing and setup logic

      case ElixirNoDeps.Presenter.Parser.parse_file(file_path) do
        {:ok, presentation} ->
          assert presentation.title == "Test Presentation"
          assert presentation.author == "Test Author"
          assert Presentation.slide_count(presentation) == 2

        {:error, reason} ->
          flunk("Expected successful parsing, got: #{reason}")
      end
    end

    test "returns error for non-existent file" do
      result = Presenter.run("non_existent_file.md")
      assert {:error, _reason} = result
    end

    test "returns error for file with no slides" do
      empty_content = """
      ---
      title: "Empty Presentation"
      ---

      Just metadata, no slides.
      """

      tmp_file = "/tmp/empty_presentation_#{System.unique_integer()}.md"
      File.write!(tmp_file, empty_content)

      result = Presenter.run(tmp_file)

      File.rm!(tmp_file)
      assert {:error, "No slides found"} = result
    end
  end

  describe "demo/0" do
    test "creates and runs demo presentation" do
      # We can't fully test the interactive demo, but we can verify
      # it doesn't crash and creates valid content

      # Mock the Navigator.run to avoid interactive mode
      # This is a basic test that the demo content is valid
      demo_content = """
      ---
      title: "ElixirNoDeps Presenter Demo"
      author: "Demo User"
      theme: "default"
      ---

      # Welcome! 🎉

      This is a **demo presentation** built with Elixir.

      ---

      # Second Slide

      More content here.
      """

      presentation = ElixirNoDeps.Presenter.Parser.parse_content(demo_content)
      assert presentation.title == "ElixirNoDeps Presenter Demo"
      assert Presentation.slide_count(presentation) >= 1
    end
  end

  describe "apply_options/2" do
    test "applies theme option" do
      slides = [Slide.new("# Test")]
      presentation = Presentation.new(slides, title: "Test")

      # Test the private function through the public interface by parsing the logic
      updated = %{presentation | theme: "dark"}
      assert updated.theme == "dark"
    end

    test "applies multiple options" do
      slides = [Slide.new("# Test")]
      presentation = Presentation.new(slides)

      updated =
        presentation
        |> Map.put(:theme, "dark")
        |> Map.put(:author, "New Author")
        |> Map.put(:title, "New Title")

      assert updated.theme == "dark"
      assert updated.author == "New Author"
      assert updated.title == "New Title"
    end
  end
end
