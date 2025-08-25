---
title: "Terminal Presentations in Elixir"
author: "Elixir Developer"
theme: "default"
---

# Welcome to Terminal Presentations

A modern approach to presentations in your terminal.

Built with Elixir's concurrency and pattern matching.

<!-- Speaker notes: Start with energy, explain why terminal presentations are cool -->

---

# Why Terminal Presentations?

- **Developer-friendly**: Stay in your comfort zone
- **Version control**: Track changes with git
- **Lightweight**: No heavy GUI applications
- **Scriptable**: Automate and integrate

---

# Features

## Core Capabilities
- Markdown-based slides
- YAML frontmatter for metadata  
- Speaker notes support
- Hot reload during development

## Navigation
- Keyboard-driven interface
- Jump to any slide
- Progress tracking

<!-- Speaker notes: Demo the navigation features here -->

---

# Code Example

```elixir
defmodule MyPresentation do
  use ElixirNoDeps.Presenter
  
  def start do
    Presenter.run("slides.md")
  end
end
```

Simple and elegant!

---

# Thank You

Questions?

GitHub: github.com/yourname/elixir-presenter

<!-- Speaker notes: Remember to ask for feedback and contributions -->