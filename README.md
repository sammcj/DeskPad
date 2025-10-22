<h3 align="center">
  <a href="https://github.com/Stengo/DeskPad/blob/main/DeskPad/Assets.xcassets/AppIcon.appiconset/Icon-256.png">
  <img src="https://github.com/Stengo/DeskPad/blob/main/DeskPad/Assets.xcassets/AppIcon.appiconset/Icon-256.png?raw=true" alt="DeskPad Icon" width="128">
  </a>
</h3>

# DeskPad
A virtual monitor for screen sharing

<h3 align="center">
  <a href="https://github.com/Stengo/DeskPad/blob/main/screenshot.jpg">
  <img src="https://github.com/Stengo/DeskPad/blob/main/screenshot.jpg?raw=true" alt="DeskPad Screenshot">
  </a>
</h3>

Certain workflows require sharing the entire screen (usually due to switching through multiple applications), but if the presenter has a much larger display than the audience it can be hard to see what is happening.

DeskPad creates a virtual display that is mirrored within its application window so that you can create a dedicated, easily shareable workspace.

# Features

- **Virtual Display**: Create a virtual monitor that can be shared or mirrored to external displays
- **Window Capture**: Capture and display a specific application window on the virtual display
- **Resolution Control**: Adjust display resolution through system preferences
- **Mouse Tracking**: Visual indication when cursor enters the virtual display

# Installation

You can either download the [latest release binary](https://github.com/Stengo/DeskPad/releases) or install via [Homebrew](https://brew.sh) by calling `brew install deskpad`.

For command-line builds:
```bash
make build    # Build the application
make package  # Build and create distributable .app bundle
make install  # Install to /Applications (requires sudo)
```

# Usage

## Full Virtual Desktop Mode (Default)
DeskPad behaves like any other display. Launching the app is equivalent to plugging in a monitor, so macOS will take care of properly arranging your windows to their previous configuration.

You can change the display resolution through the system preferences and the application window will adjust accordingly.

Whenever you move your mouse cursor to the virtual display, DeskPad will highlight its title bar in blue and move the application window to the front to let you know where you are.

<h3 align="center">
  <a href="https://github.com/Stengo/DeskPad/blob/main/demonstration.gif">
  <img src="https://github.com/Stengo/DeskPad/blob/main/demonstration.gif?raw=true" alt="DeskPad Demonstration">
  </a>
</h3>

## Window Capture Mode
Access the **Capture** menu to select a specific window to display on the virtual display:

1. Click **Capture** in the menu bar
2. Select a window from the list (shows application name and window title)
3. The selected window will be captured and displayed fullscreen on the virtual display
4. To return to normal desktop mode, select **Full Virtual Desktop** from the Capture menu

**Note**: Window Capture requires Screen Recording permissions. macOS will prompt you to grant this permission when you first select a window.

When a captured window is closed, the virtual display shows a black screen to prevent accidental sharing.
