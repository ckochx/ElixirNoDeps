# Image Support Implementation Plan

## Overview
Add support for regular image references `![alt](path)` in presentations, automatically converting them to ASCII art for terminal display.

## Current State
- ✅ ASCII art support via `![ascii](path)` syntax
- ✅ ImageMagick integration working
- ✅ PNG/JPG format support 
- ✅ Caching system in place
- ✅ Error handling for missing files

## Proposed Features

### 1. Standard Markdown Image Support
Support standard markdown image syntax: `![alt text](image_path)`

**Examples:**
```markdown
![Company Logo](images/logo.png)
![Chart](./charts/q4-results.jpg) 
![Avatar](https://example.com/avatar.png)  # Future: URL support
```

### 2. Image Processing Options
Different processing modes for different use cases:

**Syntax Options:**
- `![](image.png)` - Auto ASCII conversion (default)
- `![ascii](image.png)` - Explicit ASCII (existing)
- `![small](image.png)` - Smaller ASCII output (75px wide)
- `![large](image.png)` - Larger ASCII output (400px wide)
- `![thumbnail](image.png)` - Tiny version (50px wide)

### 3. Implementation Architecture

#### 3.1 Renderer Pipeline Extension
Extend `process_markdown_formatting/1` to handle images:

```elixir
def process_markdown_formatting(content) do
  content
  |> process_images()           # NEW: Handle ![alt](path) 
  |> AsciiProcessor.process_ascii_art()  # Existing ![ascii](path)
  |> process_headers()
  |> process_emphasis()
  |> process_code_blocks()
  |> process_lists()
end
```

#### 3.2 New Image Processor Module
Create `ElixirNoDeps.Presenter.ImageProcessor`:

```elixir
defmodule ElixirNoDeps.Presenter.ImageProcessor do
  @moduledoc """
  Processes standard markdown images in presentations.
  Converts images to ASCII art for terminal display.
  """

  # Process ![alt](path) and ![mode](path) syntax
  def process_images(content)
  
  # Determine processing mode from alt text
  def determine_image_mode(alt_text)
  
  # Convert image with specific settings
  def convert_to_ascii(image_path, mode \\ :default)
end
```

#### 3.3 Integration with Existing AsciiProcessor
- Reuse existing caching mechanism
- Reuse existing error handling
- Extend size/quality options

### 4. Processing Modes

| Mode | Alt Text | Width | Description |
|------|----------|-------|-------------|
| default | empty or descriptive | 250px | Standard conversion |
| small | "small" | 150px | Compact version |
| large | "large" | 400px | Detailed version |  
| thumbnail | "thumbnail" | 80px | Tiny preview |
| ascii | "ascii" | 250px | Explicit (existing) |

### 5. File Support
- ✅ PNG files (with alpha channel)
- ✅ JPG files  
- ✅ Relative paths
- ✅ Absolute paths
- 🔄 Future: HTTP URLs
- 🔄 Future: SVG support

### 6. Error Handling
- Missing files: Show placeholder with file path
- Invalid formats: Show format error message
- ImageMagick errors: Graceful fallback
- Network errors (future URLs): Timeout handling

## Implementation Tasks

### Phase 1: Basic Image Support
1. ✅ Research current architecture
2. 📋 Create ImageProcessor module
3. 📋 Add standard ![](path) parsing 
4. 📋 Integrate with renderer pipeline
5. 📋 Add comprehensive tests
6. 📋 Update documentation

### Phase 2: Enhanced Modes  
1. 📋 Implement size modes (small, large, thumbnail)
2. 📋 Add mode detection from alt text
3. 📋 Add tests for all modes
4. 📋 Performance optimization

### Phase 3: Advanced Features (Future)
1. 📋 HTTP URL support
2. 📋 SVG support via conversion
3. 📋 Image caching improvements
4. 📋 Async image loading

## Testing Strategy

### Unit Tests
- ImageProcessor module functions
- Mode detection logic
- Error handling scenarios
- Integration with existing AsciiProcessor

### Integration Tests  
- End-to-end image processing in presentations
- Different image formats and sizes
- Error scenarios (missing files, invalid formats)
- Caching behavior

### Test Files Needed
- test/elixir_no_deps/presenter/image_processor_test.exs
- test/fixtures/images/ (sample PNG/JPG files)
- Updated renderer tests
- Updated presentation parsing tests

## Backward Compatibility
- ✅ Existing `![ascii](path)` syntax unchanged
- ✅ All current functionality preserved  
- ✅ No breaking changes to API
- ✅ Progressive enhancement approach

## Documentation Updates
- README.md: Add image support section
- Module docs: ImageProcessor documentation  
- Examples: Sample presentations with images
- Demo updates: Include image examples

## Success Criteria
1. Standard markdown images work: `![Logo](logo.png)`
2. Multiple size modes available
3. Comprehensive test coverage >90%
4. Error handling covers all edge cases
5. Performance doesn't degrade existing features
6. Documentation is complete and clear