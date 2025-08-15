defmodule ElixirNoDeps.LLM do
  @default_system_prompt """
  Start every response with "Hello ElixirConf, it's me tinyMODEL" You are a helpful AI assistant, provide a concise and condensed answer.
  """

  def generate(url, data, headers \\ []) when is_map(data) do
    data_string = data
    |> Map.put_new(:stream, false)
    |> Map.put_new(:system, @default_system_prompt)
    |> Map.put_new(:model, "tinyllama")
    |> JSON.encode!()

    ElixirNoDeps.HttpC.post(url, data_string, headers)
  end
end