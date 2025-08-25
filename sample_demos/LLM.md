Run the LLM on the PI:

Install ollama (for macos or linux:
(Must be 64-bit pi to run ollama)

`curl -fsSL https://ollama.com/install.sh -o install.sh`

OR

```
wget https://ollama.ai/install.sh
sh ./install.sh
```
OR

`curl -fsSL https://ollama.com/install.sh | sh`

```
brew install ollama
brew services start ollama
```


2. Verify Installation:
After the script completes, you can verify the installation by checking the Ollama version:
Code

```
ollama -v
ollama pull tinyllama
ollama pull deepseek-r1:1.5b
ollama pull gemma3:1b
ollama pull phi3:3.8b
ollama pull gemma2:2b
ollama pull duckyblender/danube3:0.5b
```

OR
`ollama server`

<|system|> {{ }}</s> <|user|> {{ Tell me about the best elixir language module }}</s>


⏺ You can set the system prompt by adding a "system" field to your JSON payload:

  curl -X POST http://localhost:11434/api/generate -d '{
    "model": "tinyllama",
    "prompt": "Tell me about the best elixir language module",
    "stream": false,
    "system": "Start every response with \"Hello ElixirConf, it's me tinyllama\" You are a helpful AI assistant, provide a concise and condensed answer. "
  }' | awk -F'"response":"' '{print $2}' | awk -F'"' '{print $1}'

  Or for the chat API endpoint, you can use the messages format:

  curl -X POST http://localhost:11434/api/chat -d '{
    "model": "tinyllama",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Hello, world!"}
    ]
  }'