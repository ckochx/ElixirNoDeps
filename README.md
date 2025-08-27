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

# 8. Build the presentation tools
./scripts/build_scripts.sh

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
asdf install                # if you use asdf (recommended)
./scripts/build_scripts.sh  # builds both `present` and `remote_present` executables

# Or build individually:
mix escript.build                           # builds the `present` executable
MIX_ESCRIPT_NAME=remote_present mix escript.build  # builds the `remote_present` executable
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

### Remote control presentation

- With Mix (works everywhere):

```bash
mix remote_present path/to/slides.md
```

- With escript (generates `remote_present` in project root):

```bash
./remote_present path/to/slides.md
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

## 📱 Remote Control (Conference Mode)

Control your presentation from your phone while the audience sees a clean terminal display. Perfect for conferences where WiFi is unreliable!

### Quick Start

```bash
# Start presentation with remote control
mix remote_present slides.md
# OR
./remote_present slides.md

# With custom port
mix remote_present slides.md --port 3000
# OR
./remote_present slides.md --port 3000

# Try the demo
mix remote_present --demo
# OR
./remote_present --demo
```

### How It Works

1. **Terminal presentation** for the audience (clean, professional)
2. **Web interface** for the presenter (speaker notes + controls)
3. **Local network only** - no WiFi required

### Conference Setup (No WiFi Required)

**Step 1: Create laptop hotspot**

- **macOS**: System Preferences → Sharing → Internet Sharing
- **Windows**: Settings → Network → Mobile hotspot
- **Linux**: Settings → WiFi → Use as Hotspot

**Step 2: Connect phone to hotspot**

**Step 3: Start presentation**

```bash
mix remote_present slides.md
# OR
./remote_present slides.md
```

**Step 4: Connect to displayed URL on your phone**

- First slide shows connection URL (e.g., `http://192.168.1.100:8080`)
- Open that URL in your phone's browser
- You'll see slide controls and speaker notes

**Step 5: Present with confidence!**

- Press Enter to advance past connection slide
- Control all navigation from your phone
- Audience sees clean terminal presentation

### Speaker Notes

Add private speaker notes using HTML comments:

```markdown
# My Slide Title

Public content that audience sees.

<!-- Speaker notes: Remember to mention the key benefits. Only you see this on your phone! -->
```

### Remote Control Features

- 📱 **Mobile-optimized interface** - works on any phone/tablet
- 📝 **Speaker notes** - visible only to you
- 🎮 **Slide controls** - Next, Previous, Go to slide number
- 📊 **Progress tracking** - see current slide (e.g., "5/20")
- ⚡ **Real-time sync** - terminal updates instantly
- 🔒 **No internet required** - uses local network only

For detailed setup instructions, see [REMOTE_CONTROL_SETUP.md](REMOTE_CONTROL_SETUP.md).

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
