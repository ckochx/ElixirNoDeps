# Direct Terminal Image Rendering Plan

## Overview
Render images directly in the terminal without ASCII conversion, using modern terminal image display protocols.

## Terminal Image Rendering Technologies

### 1. Sixel Graphics
- **Support**: VT340+ compatible terminals (xterm, mlterm, foot, etc.)
- **Format**: Sixel escape sequences
- **Pros**: Wide compatibility, good quality
- **Cons**: Limited colors (216), older protocol

### 2. Kitty Graphics Protocol  
- **Support**: Kitty terminal, some others
- **Format**: Base64 encoded images via escape sequences
- **Pros**: Full color, PNG/JPEG support, excellent quality
- **Cons**: Limited terminal support

### 3. iTerm2 Inline Images
- **Support**: iTerm2 only
- **Format**: Base64 encoded images via escape sequences  
- **Pros**: Excellent integration on macOS
- **Cons**: iTerm2 specific

### 4. Terminology Inline Images
- **Support**: Terminology terminal
- **Format**: Custom escape sequences
- **Pros**: Good performance
- **Cons**: Very limited support

### 5. Unicode Block Characters (Fallback)
- **Support**: All terminals
- **Format**: Unicode block chars with ANSI colors
- **Pros**: Universal compatibility
- **Cons**: Lower quality than true image rendering

## Implementation Strategy

### Phase 1: Multi-Protocol Support
Implement detection and support for multiple protocols with graceful fallback:

```elixir
defmodule ElixirNoDeps.Presenter.ImageRenderer do
  @moduledoc """
  Renders images directly in terminals using various protocols.
  
  Supported protocols:
  - Kitty Graphics Protocol  
  - Sixel Graphics
  - iTerm2 Inline Images
  - Unicode blocks (fallback)
  """
  
  def render_image(image_path, opts \\ [])
  def detect_terminal_capabilities()
  def render_with_protocol(image_data, protocol, opts)
end
```

### Phase 2: Protocol Detection
Auto-detect terminal capabilities:

```elixir
def detect_terminal_capabilities() do
  cond do
    kitty_supported?() -> :kitty
    sixel_supported?() -> :sixel  
    iterm2_supported?() -> :iterm2
    true -> :unicode_blocks
  end
end

defp kitty_supported?() do
  # Check TERM and terminal response to capability query
  System.get_env("TERM") =~ "kitty" or 
  terminal_responds_to_kitty_query?()
end
```

### Phase 3: Image Processing Pipeline

```elixir
def render_image(image_path, opts \\ []) do
  with {:ok, image_data} <- load_image(image_path),
       {:ok, resized_data} <- resize_image(image_data, opts),
       protocol <- detect_terminal_capabilities() do
    render_with_protocol(resized_data, protocol, opts)
  else
    {:error, reason} -> render_error_placeholder(image_path, reason)
  end
end
```

## Technical Implementation

### Image Processing
Use ImageMagick for image processing:
- Resize to fit terminal dimensions
- Format conversion (PNG/JPEG → optimal format)  
- Color depth optimization per protocol

### Protocol-Specific Rendering

#### Kitty Graphics Protocol
```elixir
defp render_kitty(image_data, opts) do
  encoded = Base.encode64(image_data)
  
  # Kitty graphics escape sequence
  "\e_Ga=T,f=100,m=1;#{encoded}\e\\"
end
```

#### Sixel Graphics  
```elixir
defp render_sixel(image_path, opts) do
  # Use ImageMagick to convert to sixel
  {sixel_data, 0} = System.cmd("magick", [
    image_path, 
    "-resize", "#{opts[:width]}x#{opts[:height]}",
    "sixel:-"
  ])
  
  sixel_data
end
```

#### iTerm2 Inline Images
```elixir  
defp render_iterm2(image_data, opts) do
  encoded = Base.encode64(image_data)
  size_params = build_iterm2_size_params(opts)
  
  "\e]1337;File=#{size_params}:#{encoded}\a"
end
```

## Integration with Presentation System

### 1. Extend Renderer Pipeline
```elixir
def process_markdown_formatting(content) do
  content
  |> ImageRenderer.process_images()     # NEW: Direct image rendering
  |> AsciiProcessor.process_ascii_art() # Keep ASCII as fallback option  
  |> process_headers()
  |> process_emphasis()
  |> process_code_blocks()
  |> process_lists()
end
```

### 2. Markdown Syntax Support
- `![alt](image.png)` - Direct image rendering
- `![ascii](image.png)` - ASCII art (existing)  
- `![small](image.png)` - Small size direct rendering
- `![large](image.png)` - Large size direct rendering

### 3. Terminal Capability Detection
```elixir
# At presentation startup
def setup_presentation() do
  capabilities = ImageRenderer.detect_terminal_capabilities()
  Logger.info("Terminal image support: #{capabilities}")
  
  # Store capabilities in presentation state
  %{image_protocol: capabilities}
end
```

## Testing Strategy

### 1. Terminal Capability Tests
```elixir
defmodule ImageRendererTest do
  test "detects kitty terminal capabilities" do
    # Mock environment variables and terminal responses
  end
  
  test "falls back to unicode blocks when no image support" do
    # Test fallback behavior
  end
end
```

### 2. Protocol-Specific Tests  
- Test escape sequence generation
- Test image processing pipeline
- Test error handling

### 3. Integration Tests
- Test with sample images
- Test different terminal configurations
- Test fallback behaviors

## Implementation Tasks

### Phase 1: Foundation
1. 📋 Create ImageRenderer module
2. 📋 Implement terminal capability detection  
3. 📋 Add basic Kitty protocol support
4. 📋 Add Sixel protocol support
5. 📋 Add Unicode block fallback
6. 📋 Integrate with renderer pipeline

### Phase 2: Polish  
1. 📋 Add iTerm2 support
2. 📋 Improve image sizing and positioning
3. 📋 Add comprehensive tests
4. 📋 Performance optimization
5. 📋 Error handling improvements

### Phase 3: Advanced Features
1. 📋 Image caching for performance
2. 📋 Animation support (GIF)
3. 📋 HTTP URL support  
4. 📋 Image positioning controls

## Expected Challenges

1. **Terminal Detection**: Reliable capability detection across terminals
2. **Image Sizing**: Proper scaling for different screen sizes  
3. **Performance**: Large images in terminal can be slow
4. **Compatibility**: Graceful fallbacks when protocols not supported
5. **Testing**: Hard to test visual output in CI/CD

## Success Criteria

1. Images render directly in supported terminals
2. Automatic fallback to ASCII/Unicode when direct rendering unavailable  
3. Support for major terminals (Kitty, iTerm2, xterm with Sixel)
4. Maintains presentation performance
5. Comprehensive error handling
6. Easy to use markdown syntax

This approach provides the best of both worlds - modern direct image rendering where supported, with graceful fallbacks for older terminals.