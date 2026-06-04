# CraftOS Desktop

A full-featured windowing operating system for CC: Tweaked (ComputerCraft) Minecraft mod.

## Features

- **Window Management**: Drag, resize, minimize, and close windows
- **Taskbar**: Start menu, running app tabs, system clock
- **12 Built-in Programs**: Terminal, File Manager, Text Editor, Task Manager, Settings, Paint, Redstone Controller, Clock, Calculator, Chat, Chess, Monitor Config
- **Monitor Support**: Connect external monitors via wired modem
- **Network Chat**: Communicate with other computers via rednet
- **3 Themes**: Default (blue), Dark, and Retro (green-on-black)

## Requirements

- **Advanced Computer** (for color support and mouse events)
- **HTTP API enabled** in CC: Tweaked config (for wget installation)
- Optional: **Advanced Monitor** connected via **Wired Modem**
- Optional: **Wired Modem** for network chat with other computers

## Installation

### Method 1: Automatic Installation (Recommended)

Open your Advanced Computer and run this single command:

```lua
wget run https://raw.githubusercontent.com/VDFO/cctweaked/main/install.lua
```

This will automatically download and install all OS files.

### Method 2: Manual wget Installation

If you prefer to download files individually:

```bash
# Create directories
mkdir system
mkdir lib
mkdir programs
mkdir assets
mkdir user
mkdir user/documents

# Download core system files
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/boot.lua boot.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/startup.lua startup.lua

# Download system files
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/system/kernel.lua system/kernel.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/system/desktop.lua system/desktop.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/system/events.lua system/events.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/system/theme.lua system/theme.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/system/config.lua system/config.lua

# Download library files
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/lib/draw.lua lib/draw.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/lib/widget.lua lib/widget.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/lib/modal.lua lib/modal.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/lib/filesystem.lua lib/filesystem.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/lib/network.lua lib/network.lua

# Download programs
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/terminal.lua programs/terminal.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/filemanager.lua programs/filemanager.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/editor.lua programs/editor.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/settings.lua programs/settings.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/taskmanager.lua programs/taskmanager.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/paint.lua programs/paint.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/redstone.lua programs/redstone.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/clock.lua programs/clock.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/calculator.lua programs/calculator.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/chat.lua programs/chat.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/chess.lua programs/chess.lua
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/programs/monitor.lua programs/monitor.lua

# Download assets
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/assets/wallpaper.nfp assets/wallpaper.nfp
wget https://raw.githubusercontent.com/VDFO/cctweaked/main/user/settings.cfg user/settings.cfg
```

### Method 3: Using Pastebin

Upload `install.lua` to pastebin.cc, then run:

```lua
pastebin run PASTEBIN_CODE
```

Replace `PASTEBIN_CODE` with the actual pastebin code.

## First Boot

After installation, simply reboot the computer:

```lua
reboot
```

The OS will automatically start and display the desktop.

## Usage

### Desktop
- Click **Start** button to open program menu
- Click on desktop to deselect
- Taskbar shows running programs and clock

### Windows
- **Drag**: Click and drag title bar
- **Minimize**: Click `[_]` button
- **Close**: Click `X` button
- **Focus**: Click anywhere on window

### Keyboard Shortcuts
- **Ctrl+T**: Terminate current program
- **Q**: Quit most programs (when focused)

### Programs

#### Terminal
- Full shell access
- Command history (Up/Down arrows)
- Type `help` for available commands

#### File Manager
- Navigate with arrow keys or mouse
- **C** - Copy file
- **V** - Paste file
- **Delete** - Delete file
- **F5** - Refresh

#### Text Editor
- **Ctrl+S** - Save file
- **Ctrl+O** - Open file
- **Ctrl+N** - New file
- Arrow keys for navigation
- Full Lua syntax highlighting

#### Paint
- **T** - Cycle through tools (pencil, line, box, fill, eraser)
- Click palette to change color
- **Ctrl+S** - Save
- **Ctrl+O** - Open
- **Ctrl+N** - New canvas

#### Chess
- Click to select piece, click again to move
- Valid moves highlighted in green
- **N** - New game
- Full move validation and check/checkmate detection

#### Chat
- Type message and press Enter to send
- `/help` - Show commands
- `/msg <id>` - Private message
- `/name <name>` - Change username
- Requires modem for network functionality

#### Monitor Config
- Detects connected monitors
- Choose display mode (off/mirror/extend)
- Adjust text scale
- **T** - Test monitor
- **S** - Save settings

### Monitor Setup

1. Place a **Wired Modem** next to the computer
2. Connect **Wired Modem** to **Advanced Monitor** with networking cable
3. Right-click modem to activate
4. Open **Monitor Config** program
5. Select monitor and choose display mode
6. Click **Save**

### Network Chat Setup

1. Place **Wired Modems** on both computers
2. Connect modems with networking cable
3. Right-click both modems to activate
4. Open **Chat** program on both computers
5. Type message and press Enter to broadcast

## Themes

Change theme in **Settings** program:
- **Default**: Blue desktop with light windows
- **Dark**: Black desktop with gray windows
- **Retro**: Green-on-black terminal style

## File Structure

```
/
├── boot.lua              - Entry point
├── startup.lua           - Auto-run script
├── install.lua           - Installation script
│
├── /system/
│   ├── kernel.lua        - Process scheduler
│   ├── desktop.lua       - Window manager
│   ├── theme.lua         - Color themes
│   ├── config.lua        - Settings persistence
│   └── events.lua        - Event routing
│
├── /lib/
│   ├── widget.lua        - UI widgets
│   ├── draw.lua          - Drawing helpers
│   ├── modal.lua         - Dialog boxes
│   ├── filesystem.lua    - File I/O helpers
│   └── network.lua       - Rednet wrapper
│
├── /programs/
│   ├── terminal.lua      - Shell emulator
│   ├── filemanager.lua   - File browser
│   ├── editor.lua        - Text editor
│   ├── settings.lua      - System settings
│   ├── taskmanager.lua   - Process manager
│   ├── paint.lua         - Pixel art editor
│   ├── redstone.lua      - Redstone controller
│   ├── clock.lua         - Clock & calendar
│   ├── calculator.lua    - Calculator
│   ├── chat.lua          - Network chat
│   ├── chess.lua         - Chess game
│   └── monitor.lua       - Monitor config
│
├── /assets/
│   └── wallpaper.nfp     - Desktop background
│
└── /user/
    ├── settings.cfg      - User preferences
    └── /documents/       - User files
```

## Troubleshooting

### Computer won't boot
- Ensure you're using an **Advanced Computer** (gold trim)
- Check that `startup.lua` exists in root directory
- Verify all files were downloaded correctly with `ls`

### wget fails
- Enable HTTP API in CC: Tweaked config:
  ```
  # In .minecraft/config/computercraft.toml
  [http]
  enabled = true
  ```
- Check your internet connection
- Verify the URL is correct

### Monitor not detected
- Verify wired modem is connected and activated (right-click)
- Check networking cable connection
- Open **Monitor Config** and click **Test**

### Network chat not working
- Ensure both computers have modems connected
- Verify modems are activated (green lights)
- Check that computers are on same network

### Programs crash
- Use **Task Manager** to kill stuck processes
- Press **Ctrl+T** to terminate current program
- Reboot computer if desktop freezes

## Performance Tips

- Close unused programs to free memory
- Limit number of open windows
- Use lower text scale on monitors for better performance
- Avoid running too many parallel processes

## Technical Details

- Built on CC: Tweaked's coroutine system
- Custom kernel for process scheduling
- Event-driven architecture
- Window API for virtual terminals
- Rednet for network communication
- ~4,800 lines of Lua code

## License

Free to use and modify for Minecraft CC: Tweaked mod.

## Credits

Created for the ComputerCraft community.
Built with CC: Tweaked Lua API.
