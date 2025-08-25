# 📱 Remote Control Setup Guide

This guide shows you how to set up remote presentation control for conferences and other venues where WiFi might be unreliable.

## 🎯 What You Get

- **Audience**: Clean terminal presentation (no distractions)
- **Presenter**: Mobile web interface with speaker notes and controls
- **No WiFi needed**: Everything runs on a local network between your laptop and phone

## 🚀 Quick Start

1. **Run your presentation with remote control:**

   ```bash
   mix remote_present slides.md
   ```

2. **Connect your phone to the displayed URL**

3. **Control the presentation from your phone while the audience sees the terminal**

## 🔧 Conference Setup (No WiFi Required)

### Step 1: Create a Hotspot on Your Laptop

#### macOS

1. Go to **System Preferences > Sharing**
2. Select **Internet Sharing** from the service list
3. Choose **WiFi** as the sharing method
4. Set a network name and password
5. Enable Internet Sharing

#### Windows 10/11

1. Go to **Settings > Network & Internet > Mobile hotspot**
2. Turn on **Share my Internet connection with other devices**
3. Choose **WiFi** as the sharing method
4. Set network name and password
5. Turn on the hotspot

#### Linux (Ubuntu/Debian)

1. Go to **Settings > WiFi**
2. Click the menu (⋮) and select **Use as Hotspot**
3. Set network name and password
4. Turn on the hotspot

### Step 2: Connect Your Phone

1. On your phone, go to WiFi settings
2. Connect to the hotspot you just created
3. Use the password you set

### Step 3: Start Your Presentation

```bash
# In your presentation directory
mix remote_present slides.md

# Or with a custom port
mix remote_present slides.md --port 3000
```

You'll see output like:

```
🌐 Remote Control Server Started!
📱 Connect your phone to: http://192.168.1.100:8080
🎯 Audience sees presentation in terminal
📝 You'll see speaker notes on your phone
```

### Step 4: Control from Your Phone

1. Open the URL shown in your phone's browser
2. You'll see the current slide, speaker notes, and navigation controls
3. Use the buttons to navigate through your presentation
4. The audience will see slides change in real-time in the terminal

## 📝 Adding Speaker Notes

Add speaker notes to your markdown slides using HTML comments:

```markdown
# My Slide Title

Public content that the audience sees.

<!-- Speaker notes: Remember to speak slowly and make eye contact. This slide introduces the main topic. -->

---

# Next Slide

More public content.

<!-- Speaker notes: This is a good place to ask questions and engage the audience. -->
```

## 🎮 Remote Control Features

### Mobile Interface

- **Current slide preview**: See what the audience is seeing
- **Speaker notes**: Private notes visible only to you
- **Navigation controls**: Next, Previous, Go to specific slide
- **Slide counter**: Track your progress (e.g., "5 / 20")

### Real-time Sync

- Terminal updates instantly when you navigate on your phone
- No lag or delay in slide transitions
- Robust connection handling

## 🛠 Troubleshooting

### Can't Connect to Remote URL

1. **Check the IP address**: Make sure your phone is connected to the laptop's hotspot
2. **Verify the port**: Ensure no other applications are using the port (default: 8080)
3. **Firewall**: Make sure your laptop's firewall allows connections on the web server port

### Web Interface Not Loading

1. **Try a different port**:

   ```bash
   mix remote_present slides.md --port 3000
   ```

2. **Check browser compatibility**: Use a modern browser on your phone

3. **Restart the hotspot**: Turn off and on the laptop's hotspot

### Slides Not Changing

1. **Refresh the web page** on your phone
2. **Check the terminal** for any error messages
3. **Restart the presentation** if needed

## 🎨 Customization

### Custom Port

```bash
# Use port 3000 instead of default 8080
mix remote_present slides.md --port 3000
```

### Programmatic Usage

```elixir
# In your Elixir code
ElixirNoDeps.RemotePresenter.run("slides.md", web_port: 8080)

# Run a demo
ElixirNoDeps.RemotePresenter.demo(web_port: 3000)
```

## 🎤 Conference Best Practices

1. **Test beforehand**: Set up your hotspot and test the connection before your talk

2. **Backup plan**: Have keyboard navigation as a backup (space bar, arrow keys work in terminal)

3. **Battery**: Ensure your laptop and phone are fully charged

4. **Screen mirroring**: Use a wireless presenter display or HDMI cable to project the terminal

5. **Slide numbers**: Keep track of your progress with the slide counter

## 🔍 Technical Details

- **Web server**: Pure Elixir HTTP server (no external dependencies)
- **Communication**: Web interface communicates with the Navigator GenServer
- **JSON API**: RESTful endpoints for slide navigation and status
- **Mobile optimized**: Responsive design works on any screen size

## 📱 Demo

Try the built-in demo to see how it works:

```bash
mix remote_present --demo
```

This creates a sample presentation that demonstrates all the remote control features.

## ❓ FAQ

**Q: Does this require an internet connection?**
A: No! It creates a local network between your laptop and phone.

**Q: Can multiple people control the presentation?**
A: Yes, anyone connected to your hotspot can access the control URL.

**Q: What if my phone battery dies?**
A: You can still use keyboard navigation in the terminal as a backup.

**Q: Does this work with any presentation?**
A: Yes, any markdown presentation with frontmatter will work.

**Q: Can I see what the audience sees?**
A: Yes, the web interface shows the current slide content.

---

**Happy presenting! 🎯📱**

For more information, see the project documentation or run `mix remote_present --help`.
