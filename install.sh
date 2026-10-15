#!/usr/bin/env bash
# RIPPER installer
#   ./install.sh              install ripper
#   ./install.sh --neofetch   also install the neofetch logo
#   ./install.sh --uninstall  remove ripper (and the neofetch logo)
set -euo pipefail

REPO="jeremycru56-gif/ripper-adb"
BRANCH="main"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"

BIN_DIR="${RIPPER_PREFIX:-${PREFIX:-$HOME/.local}}/bin"
TARGET="$BIN_DIR/ripper"
NEO_FILE="$HOME/.config/neofetch/ascii/ripper.txt"

P=$'\e[38;5;129m'; D=$'\e[38;5;54m'; W=$'\e[38;5;255m'; R=$'\e[0m'
ok()   { echo " ${P}[+]${R} $*"; }
warn() { echo " ${D}[!]${R} ${W}$*${R}"; }
die()  { warn "$*"; exit 1; }

# where this script lives (empty when run through "curl | bash")
here=""
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# fetch <path in repo> <destination>
fetch() {
  if [ -n "$here" ] && [ -f "$here/$1" ]; then
    cp "$here/$1" "$2"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$RAW/$1" -o "$2" || die "download failed: $1"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$2" "$RAW/$1" || die "download failed: $1"
  else
    die "need curl or wget"
  fi
}

install_ripper() {
  local tmp
  mkdir -p "$BIN_DIR"
  tmp="$(mktemp)"
  fetch ripper.sh "$tmp"
  head -n 1 "$tmp" | grep -q '^#!' || die "ripper.sh looks wrong, aborting"
  install -m 755 "$tmp" "$TARGET"
  rm -f "$tmp"
  ok "installed → $TARGET"

  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR is not in your PATH. Add this to your shell rc:"
       echo "     export PATH=\"$BIN_DIR:\$PATH\"" ;;
  esac

  if ! command -v adb >/dev/null 2>&1; then
    warn "adb not found. Install it first:"
    echo "     Debian/Ubuntu : sudo apt install adb"
    echo "     macOS         : brew install android-platform-tools"
    echo "     Arch          : sudo pacman -S android-tools"
    echo "     Termux        : pkg install android-tools"
  fi
  ok "run it with: ripper"
}

install_neofetch() {
  mkdir -p "$(dirname "$NEO_FILE")"
  fetch neofetch-ripper.txt "$NEO_FILE"
  ok "neofetch logo → $NEO_FILE"
  echo "     add to ~/.config/neofetch/config.conf:"
  echo "       image_backend=\"ascii\""
  echo "       image_source=\"\$HOME/.config/neofetch/ascii/ripper.txt\""
  echo "       ascii_colors=(129 54)"
}

uninstall_ripper() {
  rm -f "$TARGET" "$NEO_FILE"
  ok "removed $TARGET (captures in ~/ripper_captures were kept)"
}

want_neo=0
case "${1:-}" in
  "")          ;;
  --neofetch)  want_neo=1 ;;
  --uninstall) uninstall_ripper; exit 0 ;;
  -h|--help)   sed -n '2,5p' "${BASH_SOURCE[0]:-/dev/null}" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
  *)           die "unknown option: $1" ;;
esac

install_ripper
[ "$want_neo" -eq 1 ] && install_neofetch
exit 0
