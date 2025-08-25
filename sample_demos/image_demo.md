# Image Rendering Demo

Welcome to the image rendering demonstration!

---

# Standard Image Rendering

Here's a standard image using default settings:

![Tiny Llama](tinyllama.png)

This should render directly in your terminal.

---

# Sized Image Rendering

Small version:
![small](test/fixtures/images/test_red.jpg)

Thumbnail version:
![thumbnail](test/fixtures/images/test_blue.png)

Large version:
![large](test/fixtures/images/test_red.jpg)

---

# Mixed Content

You can mix images with other content:

## Project Results
- ✅ Direct terminal image rendering
- ✅ Multi-protocol support (iTerm2, Kitty, Sixel)
- ✅ Graceful fallbacks

![Blue Results](test/fixtures/images/test_blue.png)

**Great success!**

---

# ASCII Fallback

This still works with ASCII conversion:
![ascii](test/fixtures/images/test_red.jpg)

---

# Error Handling

Missing image test:
![Missing](nonexistent.png)

The system should show an error message instead of crashing.