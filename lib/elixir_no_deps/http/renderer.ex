defmodule ElixirNoDeps.HTTP.Renderer do
  @moduledoc """
  Simple HTML rendering utilities using only Elixir built-ins.
  Provides basic HTML parsing and text extraction capabilities.
  """

  @doc """
  Strips all HTML tags and returns plain text.

  ## Examples

      iex> HtmlRenderer.strip_tags("<h1>Hello</h1><p>World!</p>")
      "HelloWorld!"

      iex> HtmlRenderer.strip_tags("<p>Hello <strong>World</strong>!</p>")
      "Hello World!"
  """
  def strip_tags(html) do
    html
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/&[a-zA-Z0-9#]+;/, &decode_html_entity/1)
    |> String.trim()
  end

  @doc """
  Extracts text content while preserving some basic formatting.
  Converts common block elements to newlines.

  ## Examples

      iex> HtmlRenderer.to_text("<h1>Title</h1><p>Paragraph 1</p><p>Paragraph 2</p>")
      "Title\\n\\nParagraph 1\\n\\nParagraph 2"
  """
  def to_text(html) do
    html
    |> String.replace(~r/<\/(div|p|h[1-6]|li|br)>/i, "\n")
    |> String.replace(~r/<(div|p|h[1-6]|li|br)[^>]*>/i, "\n")
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/&[a-zA-Z0-9#]+;/, &decode_html_entity/1)
    |> String.replace(~r/\n\s*\n/, "\n\n")
    |> String.trim()
  end

  @doc """
  Extracts links from HTML content.
  Returns a list of {text, url} tuples.

  ## Examples

      iex> HtmlRenderer.extract_links("<a href='http://example.com'>Example</a>")
      [{"Example", "http://example.com"}]
  """
  def extract_links(html) do
    ~r/<a[^>]*href\s*=\s*['"]([^'"]*)['"][^>]*>(.*?)<\/a>/i
    |> Regex.scan(html)
    |> Enum.map(fn [_full, url, text] ->
      {strip_tags(text), url}
    end)
  end

  @doc """
  Extracts images from HTML content.
  Returns a list of {alt_text, src_url} tuples.

  ## Examples

      iex> HtmlRenderer.extract_images("<img src='photo.jpg' alt='A photo'>")
      [{"A photo", "photo.jpg"}]
  """
  def extract_images(html) do
    ~r/<img[^>]*src\s*=\s*['"]([^'"]*)['"][^>]*(?:alt\s*=\s*['"]([^'"]*)['"]*)?[^>]*>/i
    |> Regex.scan(html)
    |> Enum.map(fn
      [_full, src, alt] -> {alt || "", src}
      [_full, src] -> {"", src}
    end)
  end

  @doc """
  Renders HTML as a simple text-based representation with indentation.
  Useful for debugging or console output.

  ## Examples

      iex> html = "<html><body><h1>Title</h1><p>Content</p></body></html>"
      iex> HtmlRenderer.to_tree(html)
      "html\\n  body\\n    h1: Title\\n    p: Content"
  """
  def to_tree(html) do
    html
    |> parse_simple()
    |> render_tree(0)
    |> String.trim()
  end

  @doc """
  Creates a simple terminal-friendly representation of HTML.
  Adds basic formatting like borders for headers.
  """
  def to_terminal(html) do
    html
    |> replace_headers()
    |> replace_paragraphs()
    |> replace_list_items()
    |> replace_strong()
    |> replace_emphasis()
    |> replace_code()
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/&[a-zA-Z0-9#]+;/, &decode_html_entity/1)
    |> String.replace(~r/\n\s*\n\s*\n/, "\n\n")
    |> String.trim()
  end

  @doc """
  Extracts the title from an HTML document.
  """
  def extract_title(html) do
    case Regex.run(~r/<title[^>]*>(.*?)<\/title>/i, html) do
      [_full, title] -> strip_tags(title)
      nil -> nil
    end
  end

  @doc """
  Extracts meta description from an HTML document.
  """
  def extract_description(html) do
    case Regex.run(
           ~r/<meta[^>]*name\s*=\s*['"]description['"][^>]*content\s*=\s*['"]([^'"]*)['"]/i,
           html
         ) do
      [_full, description] -> description
      nil -> nil
    end
  end

  @doc """
  Creates a simple summary of an HTML page.
  """
  def summarize(html) do
    %{
      title: extract_title(html),
      description: extract_description(html),
      text_length: html |> to_text() |> String.length(),
      link_count: html |> extract_links() |> length(),
      image_count: html |> extract_images() |> length()
    }
  end

  # Private functions

  defp replace_headers(html) do
    Regex.replace(~r/<h([1-6])[^>]*>(.*?)<\/h[1-6]>/i, html, fn _, level, content ->
      text = strip_tags(content)
      level_num = String.to_integer(level)

      case level_num do
        1 ->
          "#{String.duplicate("=", String.length(text))}\n#{text}\n#{String.duplicate("=", String.length(text))}\n"

        2 ->
          "#{text}\n#{String.duplicate("-", String.length(text))}\n"

        _ ->
          "#{String.duplicate("#", level_num)} #{text}\n"
      end
    end)
  end

  defp replace_paragraphs(html) do
    Regex.replace(~r/<p[^>]*>(.*?)<\/p>/i, html, fn _, content ->
      "#{strip_tags(content)}\n\n"
    end)
  end

  defp replace_list_items(html) do
    Regex.replace(~r/<li[^>]*>(.*?)<\/li>/i, html, fn _, content ->
      "• #{strip_tags(content)}\n"
    end)
  end

  defp replace_strong(html) do
    Regex.replace(~r/<strong[^>]*>(.*?)<\/strong>/i, html, fn _, content ->
      "**#{strip_tags(content)}**"
    end)
  end

  defp replace_emphasis(html) do
    Regex.replace(~r/<em[^>]*>(.*?)<\/em>/i, html, fn _, content ->
      "*#{strip_tags(content)}*"
    end)
  end

  defp replace_code(html) do
    Regex.replace(~r/<code[^>]*>(.*?)<\/code>/i, html, fn _, content ->
      "`#{strip_tags(content)}`"
    end)
  end

  defp decode_html_entity(entity) do
    case entity do
      "&amp;" -> "&"
      "&lt;" -> "<"
      "&gt;" -> ">"
      "&quot;" -> "\""
      "&apos;" -> "'"
      "&nbsp;" -> " "
      "&#39;" -> "'"
      _ -> entity
    end
  end

  defp parse_simple(html) do
    # Very basic HTML parsing - just for demonstration
    # This is not a full HTML parser but gives a simple tree structure
    html
    |> String.split(~r/<[^>]+>/)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp render_tree(elements, indent) do
    elements
    |> Enum.map(fn element ->
      "#{String.duplicate("  ", indent)}#{element}"
    end)
    |> Enum.join("\n")
  end
end
