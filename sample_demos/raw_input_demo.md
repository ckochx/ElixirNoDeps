---
title: "Raw Keyboard Input Demo"
author: "ElixirNoDeps Presenter"
theme: "default"
---

# Raw Keyboard Input! 🚀

Welcome to the improved presentation system with **raw keyboard input**.

No more pressing Enter after every key!

---

# How It Works

The presentation now captures keystrokes directly using:

- **Terminal raw mode** via `stty` commands
- **Escape sequence parsing** for arrow keys  
- **Control character detection** for Ctrl+C, etc.
- **Graceful fallback** if raw mode fails

---

# Supported Keys

## Navigation
- **Space**, **→**, **↓**, **n**, **j**, **Enter** → Next slide
- **←**, **↑**, **p**, **k**, **h**, **Backspace** → Previous slide
- **0**, **Home** → First slide
- **$**, **End** → Last slide
- **1-9** → Jump to specific slide

---

# Control Keys

## Quit Commands
- **q**, **Q** → Quit normally
- **Ctrl+C**, **Ctrl+D** → Force quit

## Utilities  
- **r** → Refresh/redraw screen
- **?**, **/**, **F1** → Show help

---

# Technical Details

```elixir
# Raw input capture
def get_raw_key do
  case RawInput.get_raw_key() do
    " " -> :next_slide      # Spacebar
    :arrow_right -> :next_slide
    :ctrl_c -> :quit
    key -> process_key(key)
  end
end
```

The system automatically **enables** raw mode on start and **restores** normal mode on exit.

---

# User Experience

## Before (with Enter)
1. Press Space
2. **Press Enter** ⏳ 
3. Slide advances

## Now (raw input) 
1. Press Space ⚡
2. Slide advances immediately!

**Much more fluid and responsive!**

---

# Implementation Benefits

- **Zero latency** navigation
- **Professional feel** like other presentation tools
- **Multiple input methods** (vim keys, arrows, etc.)
- **Robust error handling** with terminal restoration
- **Cross-platform compatibility** using standard `stty`

---

# Try It Now!

Press different keys to see the raw input in action:

- Try **arrow keys** for navigation
- Use **vim keys** (h, j, k, l)
- Test **Ctrl+C** to quit gracefully
- Press **?** for the help screen

**No Enter key required!** ✨

---

# Thank You!

Raw keyboard input makes presentations feel **professional** and **responsive**.

Perfect for live demos and presentations!

Press **q** to exit when ready.