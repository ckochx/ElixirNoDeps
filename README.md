# ElixirNoDeps

Terminal-based presentation tool and utilities with zero external Mix deps.

- Present markdown files in your terminal
- Keyboard navigation (space/enter to advance, arrows, vim keys)
- Optional inline image rendering (sixel) when available
- Includes a simple ASCII art generator for images

## Express Setup for Mac

Complete setup from scratch (no Elixir required):

```bash
# 1. Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install asdf version manager
brew install asdf

# 3. Add asdf to your shell (choose your shell)
# For bash:
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.bash_profile
# For zsh:
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc

# 4. Restart your terminal or source your profile
source ~/.bash_profile  # or ~/.zshrc

# 5. Install Elixir and Erlang plugins
asdf plugin add erlang
asdf plugin add elixir

# 6. Clone this repository
git clone https://github.com/ckochx/ElixirNoDeps.git
cd ElixirNoDeps

# 7. Install the exact versions specified in .tool-versions
asdf install

# 8. Build the presentation tool
mix escript.build

# 9. Try it out!
./present sample_presentation.md
```

**Optional: Enhanced experience with images**

```bash
# Install ImageMagick for ASCII art generation
brew install imagemagick

# Install iTerm2 for sixel image support
brew install --cask iterm2
# Then in iTerm2: Preferences → Profiles → Terminal → Enable "Sixel scrolling"
```

## Prerequisites

- Elixir/Erlang toolchain. If you use `asdf`, this repo includes a `.tool-versions` file.
  - From the project root: `asdf install`

## Local setup

```bash
# From project root
asdf install           # if you use asdf (recommended)
mix escript.build      # builds the `present` executable
```

## Usage

### Present a markdown file

- With Mix (works everywhere):

```bash
mix present path/to/slides.md
```

- With escript (generates `present` in project root):

```bash
./present path/to/slides.md
```

### Navigation

- **Next slide**: Just press **Enter** (or Space+Enter, n+Enter)
- **Previous slide**: `p`+Enter (or k+Enter, h+Enter)
- **First slide**: `0`+Enter
- **Last slide**: `$`+Enter
- **Jump to slide**: `1-9`+Enter
- **Refresh**: `r`+Enter
- **Help**: `?`+Enter or `/`+Enter
- **Quit**: `q`+Enter

Note: All commands require pressing Enter after the key. This ensures reliable navigation across all terminal environments.

### ASCII image utility

Generate ASCII art from an image:

```bash
mix asciify path/to/image.png
```

## Optional image rendering (sixel)

Inline images in the terminal are supported via sixel when both ImageMagick and a sixel-compatible terminal are available:

### Requirements

- **ImageMagick**: Install with `brew install imagemagick`
- **Sixel-compatible terminal**: Standard terminals like Terminal.app don't support sixel

### Sixel-Compatible Terminals

- **iTerm2** (recommended for macOS):
  ```bash
  brew install --cask iterm2
  ```

### Fallback Behavior

If sixel is not available, images will be rendered as ASCII art (which may appear as compressed text). The presentation will still run normally.

## Development

Run tests:

```bash
mix test
```

Some tests depend on ImageMagick. To skip them:

```bash
mix test --exclude requires_imagemagick
```

## Credits

- Inspired by the idea of building useful tools with no external Mix dependencies
- Courtesy of: https://github.com/papa-whisky and https://github.com/papa-whisky/elixir_ascii_image
