# ElixirNoDeps

Terminal-based presentation tool and utilities with zero external Mix deps.

- Present markdown files in your terminal
- Keyboard navigation (space/enter to advance, arrows, vim keys)
- Optional inline image rendering (sixel) when available
- Includes a simple ASCII art generator for images

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

- Next slide: Space, Enter, →, ↓, `n`, `j`
- Previous slide: ←, ↑, `p`, `k`, `h`, Backspace
- First/Last: `0` (Home), `$` (End)
- Jump: `1-9`
- Other: `r` = refresh, `?` or `/` = help, `q` = quit

Note: Depending on your terminal environment, arrow keys may require running the escript directly for best results.

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
