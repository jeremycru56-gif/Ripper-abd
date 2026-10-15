# RIPPER

A purple-and-black terminal toolkit that wraps `adb` so you can manage your Android phone from a simple menu instead of remembering commands.

```
  ▄████████  ▄█     ▄███████▄    ▄███████▄    ▄████████    ▄████████
  ███    ███ ███    ███    ███   ███    ███   ███    ███   ███    ███
  ███    ███ ███▌   ███    ███   ███    ███   ███    █▀    ███    ███
 ▄███▄▄▄▄██▀ ███▌   ███    ███   ███    ███  ▄███▄▄▄      ▄███▄▄▄▄██▀
▀▀███▀▀▀▀▀   ███▌ ▀█████████▀  ▀█████████▀  ▀▀███▀▀▀     ▀▀███▀▀▀▀▀
▀███████████ ███    ███          ███          ███    █▄  ▀███████████
  ███    ███ ███    ███          ███          ███    ███   ███    ███
  ███    ███ █▀    ▄████▀       ▄████▀        ██████████   ███    ███
  ███    ███                                               ███    ███
```

## Features

- Wi-Fi connect (USB → wireless) and pairing for Android 11+
- Device info: model, Android version, battery, storage, RAM
- Screenshot and screen recording, saved to `~/ripper_captures`
- Install APKs (drag the file into the terminal)
- List, search and uninstall apps
- Push and pull files
- Live logcat or a saved snapshot
- Screen mirroring through `scrcpy` (optional)
- Reboot to system, recovery or bootloader, plus a quick `adb shell`
- Multi-device support: pick which phone to control

## Requirements

- `bash` 3.2 or newer (Linux, macOS, WSL, Termux)
- `adb` from Android platform-tools
- Optional: `scrcpy` for screen mirroring

| System | Install adb |
| --- | --- |
| Debian / Ubuntu | `sudo apt install adb` |
| macOS | `brew install android-platform-tools` |
| Arch | `sudo pacman -S android-tools` |
| Termux | `pkg install android-tools` |

## Install

```bash
git clone https://github.com/jeremycru56-gif/Ripper-abd.git
cd Ripper-abd
./install.sh
```

Or in one line:

```bash
curl -fsSL https://raw.githubusercontent.com/jeremycru56-gif/Ripper-abd/main/install.sh | bash
```

This puts `ripper` in `~/.local/bin`. If that folder isn't in your `PATH`, the installer tells you what to add. Set `RIPPER_PREFIX` to install somewhere else.

Want the matching neofetch logo too?

```bash
./install.sh --neofetch
```

To remove everything:

```bash
./install.sh --uninstall
```

## Phone setup

1. Open Settings → About phone and tap **Build number** 7 times.
2. Open Developer options and turn on **USB debugging**.
3. Plug the phone in and accept the "Allow USB debugging?" prompt.

## Usage

```bash
ripper              # open the menu
ripper --version
ripper --help
```

Pick a number from the menu. Press `Ctrl+C` to stop a running command such as live logcat, and choose `0` to exit.

## Neofetch logo

The installer's `--neofetch` option copies the logo to `~/.config/neofetch/ascii/ripper.txt`. Then add this to `~/.config/neofetch/config.conf`:

```bash
image_backend="ascii"
image_source="$HOME/.config/neofetch/ascii/ripper.txt"
ascii_colors=(129 54)
colors=(129 93 129 129 129 255)
```

## Responsible use

RIPPER only wraps standard `adb` commands. Use it on devices you own or have clear permission to debug. You are responsible for what you do with it.

## License

MIT, see [LICENSE](LICENSE).
