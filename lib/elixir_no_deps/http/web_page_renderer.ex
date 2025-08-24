# Example usage module
defmodule ElixirNoDeps.HTTP do
  defmodule WebPageRenderer do
    @moduledoc """
    Combines ElixirNoDeps.HTTP.Client and ElixirNoDeps.HTTP.Renderer to fetch and render web pages.
    """

    @doc """
    Fetches a web page and renders it as plain text.
    """
    def fetch_and_render_text(url) do
      case ElixirNoDeps.HTTP.Client.get_body(url) do
        {:ok, html} ->
          {:ok, ElixirNoDeps.HTTP.Renderer.to_text(html)}

        {:error, reason} ->
          {:error, reason}
      end
    end

    @doc """
    Fetches a web page and renders it in terminal-friendly format.
    """
    def fetch_and_render_terminal(url) do
      case ElixirNoDeps.HTTP.Client.get_body(url) do
        {:ok, html} ->
          {:ok, ElixirNoDeps.HTTP.Renderer.to_terminal(html)}

        {:error, reason} ->
          {:error, reason}
      end
    end

    @doc """
    Fetches a web page and extracts key information.
    """
    def fetch_and_summarize(url) do
      case ElixirNoDeps.HTTP.Client.get_body(url) do
        {:ok, html} ->
          summary = ElixirNoDeps.HTTP.Renderer.summarize(html)
          {:ok, Map.put(summary, :url, url)}

        {:error, reason} ->
          {:error, reason}
      end
    end

    @doc """
    Fetches a web page and extracts all links.
    """
    def fetch_and_extract_links(url) do
      case ElixirNoDeps.HTTP.Client.get_body(url) do
        {:ok, html} ->
          {:ok, ElixirNoDeps.HTTP.Renderer.extract_links(html)}

        {:error, reason} ->
          {:error, reason}
      end
    end

    @doc """
    Fetches a web page and prints it directly to the terminal.
    """
    def print_page(url) do
      case fetch_and_render_terminal(url) do
        {:ok, content} ->
          IO.puts(content)
          :ok

        {:error, reason} ->
          IO.puts("Error fetching #{url}: #{inspect(reason)}")
          {:error, reason}
      end
    end

    @doc """
    Fetches a web page and prints it with a header.
    """
    def print_page_with_header(url) do
      IO.puts("Fetching: #{url}")
      IO.puts(String.duplicate("=", String.length("Fetching: #{url}")))
      IO.puts("")

      case fetch_and_render_terminal(url) do
        {:ok, content} ->
          IO.puts(content)
          IO.puts("")
          IO.puts("--- End of page ---")
          :ok

        {:error, reason} ->
          IO.puts("Error: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end
end
