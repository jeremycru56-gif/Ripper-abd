#!/usr/bin/env bash
# RIPPER :: purple ADB toolkit for Android phones
# Needs: adb (Android platform-tools). Optional: scrcpy for screen mirroring.
# Phone setup: Settings > About phone > tap "Build number" 7 times,
# then Developer options > enable "USB debugging" and accept the prompt.

VERSION="1.0.0"

case "${1:-}" in
  -v|--version)
    echo "ripper $VERSION"
    exit 0
    ;;
  -h|--help)
    cat << 'HELP'
RIPPER - purple ADB toolkit for Android phones

Usage:
  ripper              open the interactive menu
  ripper --version    print the version
  ripper --help       show this help

Needs adb (Android platform-tools). Optional: scrcpy.
Captures are saved to ~/ripper_captures
Only use on devices you own or have permission to debug.
HELP
    exit 0
    ;;
esac

P=$'\e[38;5;129m'   # bright purple
D=$'\e[38;5;54m'    # deep purple
L=$'\e[38;5;183m'   # light lavender
W=$'\e[38;5;255m'   # white
R=$'\e[0m'

OUT="$HOME/ripper_captures"
mkdir -p "$OUT"
trap 'echo' INT   # ctrl+c stops adb commands, not the whole menu

# ---------- helpers ----------
ok()    { echo " ${P}[+]${R} $*"; }
bad()   { echo " ${D}[!]${R} ${W}$*${R}"; }
ask()   { read -r -p " ${P}»${R} $1 " "$2"; }
pause() { echo; read -r -p " ${D}enter to continue...${R}" _; }
stamp() { date +%Y%m%d_%H%M%S; }
prop()  { adb shell getprop "$1" 2>/dev/null | tr -d '\r'; }
row()   { printf '   %s%-14s%s %s\n' "$P" "$1" "$R" "$2"; }
item()  { printf '   %s%2s%s %s»%s %s%s%s\n' "$P" "$1" "$R" "$D" "$R" "$L" "$2" "$R"; }

clean_path() {
  local f="$1"
  f="${f//\\ / }"
  f="${f%\'}"; f="${f#\'}"; f="${f%\"}"; f="${f#\"}"
  echo "${f/#\~/$HOME}"
}

need_device() {
  if ! adb get-state >/dev/null 2>&1; then
    bad "no device (or more than one). Try option 1 or 3 first."
    return 1
  fi
}

banner() {
  clear
  printf '%s' "$P"
  cat << 'EOF'

  ▄████████  ▄█     ▄███████▄    ▄███████▄    ▄████████    ▄████████ 
  ███    ███ ███    ███    ███   ███    ███   ███    ███   ███    ███ 
  ███    ███ ███▌   ███    ███   ███    ███   ███    █▀    ███    ███ 
 ▄███▄▄▄▄██▀ ███▌   ███    ███   ███    ███  ▄███▄▄▄      ▄███▄▄▄▄██▀ 
▀▀███▀▀▀▀▀   ███▌ ▀█████████▀  ▀█████████▀  ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   
EOF
  printf '%s' "$D"
  cat << 'EOF'
▀███████████ ███    ███          ███          ███    █▄  ▀███████████ 
  ███    ███ ███    ███          ███          ███    ███   ███    ███ 
  ███    ███ █▀    ▄████▀       ▄████▀        ██████████   ███    ███ 
  ███    ███                                               ███    ███ 
EOF
  printf '%s\n' "$R"
  echo "   ${D}──────────────${R}  ${L}android debug toolkit${R}  ${D}──────────────${R}"
}

status() {
  if adb get-state >/dev/null 2>&1; then
    echo "   ${P}●${R} ${W}$(prop ro.product.manufacturer) $(prop ro.product.model)${R} ${D}::${R} ${L}android $(prop ro.build.version.release)${R}"
  else
    echo "   ${D}○ no device connected${R}"
  fi
}

menu() {
  echo
  item 1  "wifi connect (usb → wireless)"
  item 2  "device info"
  item 3  "select device (if several)"
  item 4  "screenshot"
  item 5  "screen record"
  item 6  "install apk"
  item 7  "list / search apps"
  item 8  "uninstall app"
  item 9  "push file to phone"
  item 10 "pull file from phone"
  item 11 "logcat"
  item 12 "mirror screen (scrcpy)"
  item 13 "reboot"
  item 14 "open adb shell"
  item 15 "wifi pair (android 11+)"
  item 16 "disconnect wireless"
  item 0  "exit"
  echo
}

# ---------- actions ----------
pick_device() {
  local devs=() d i=1 pick
  while read -r d; do devs+=("$d"); done < <(adb devices | awk 'NR>1 && $2=="device"{print $1}')
  if [ ${#devs[@]} -eq 0 ]; then
    bad "no authorized devices. Plug in, enable USB debugging, accept the prompt."
    adb devices
    return
  fi
  for d in "${devs[@]}"; do
    echo "   ${P}$i${R}) ${L}$d${R}"
    i=$((i + 1))
  done
  ask "pick #" pick
  if [[ "$pick" =~ ^[0-9]+$ ]] && [ "$pick" -ge 1 ] && [ "$pick" -le ${#devs[@]} ]; then
    export ANDROID_SERIAL="${devs[$((pick - 1))]}"
    ok "locked to $ANDROID_SERIAL"
  else
    bad "invalid choice"
  fi
}

do_info() {
  need_device || return
  local lvl tmp
  lvl=$(adb shell dumpsys battery | tr -d '\r' | awk -F': ' '/^ *level:/{print $2}')
  tmp=$(adb shell dumpsys battery | tr -d '\r' | awk -F': ' '/^ *temperature:/{print $2}')
  echo
  row "brand"      "$(prop ro.product.brand)"
  row "model"      "$(prop ro.product.model)"
  row "android"    "$(prop ro.build.version.release) (SDK $(prop ro.build.version.sdk))"
  row "patch"      "$(prop ro.build.version.security_patch)"
  row "cpu abi"    "$(prop ro.product.cpu.abi)"
  row "serial"     "$(adb get-serialno)"
  row "battery"    "${lvl:-?}%  ${tmp:+$((tmp / 10))°C}"
  row "storage"    "$(adb shell df -h /data | tail -1 | awk '{print $3 " used of " $2}')"
  row "ram"        "$(adb shell cat /proc/meminfo | awk '/MemTotal/{printf "%.1f GB", $2/1048576}')"
}

do_wifi() {
  need_device || return
  local ip
  ip=$(adb shell ip -f inet addr show wlan0 2>/dev/null | tr -d '\r' | awk '/inet /{split($2,a,"/"); print a[1]; exit}')
  if [ -z "$ip" ]; then
    bad "couldn't read the wifi IP. Is the phone on wifi?"
    return
  fi
  adb tcpip 5555 >/dev/null
  sleep 2
  adb connect "$ip:5555"
  ok "if it says connected, you can unplug the cable ($ip:5555)"
}

do_pair() {
  local hp
  echo " ${D}phone: Developer options > Wireless debugging > Pair with code${R}"
  ask "pairing ip:port:" hp
  [ -z "$hp" ] && return
  adb pair "$hp"
  ask "connect ip:port (main screen of wireless debugging):" hp
  [ -n "$hp" ] && adb connect "$hp"
}

do_disconnect() { adb disconnect; }

do_shot() {
  need_device || return
  local f="$OUT/screen_$(stamp).png"
  adb exec-out screencap -p > "$f"
  if [ -s "$f" ]; then ok "saved → $f"; else rm -f "$f"; bad "screenshot failed"; fi
}

do_record() {
  need_device || return
  local t f tmp=/sdcard/ripper_tmp.mp4
  ask "seconds (1-180, default 15):" t
  if ! { [[ "$t" =~ ^[0-9]+$ ]] && [ "$t" -ge 1 ] && [ "$t" -le 180 ]; }; then t=15; fi
  f="$OUT/rec_$(stamp).mp4"
  ok "recording ${t}s..."
  adb shell screenrecord --time-limit "$t" "$tmp"
  adb pull "$tmp" "$f" >/dev/null 2>&1
  adb shell rm "$tmp"
  if [ -s "$f" ]; then ok "saved → $f"; else bad "recording failed"; fi
}

do_install() {
  need_device || return
  local f
  ask "apk path (drag the file in):" f
  f=$(clean_path "$f")
  if [ -f "$f" ]; then adb install -r "$f"; else bad "file not found"; fi
}

do_apps() {
  need_device || return
  local q
  ask "filter (blank = all user apps):" q
  adb shell pm list packages -3 | tr -d '\r' | sed 's/^package://' | grep -i -- "$q" | sort
}

do_uninstall() {
  need_device || return
  local p c
  ask "package name (e.g. com.example.app):" p
  [ -z "$p" ] && return
  ask "remove ${p}? (y/N)" c
  if [[ "$c" =~ ^[Yy]$ ]]; then adb uninstall "$p"; else bad "cancelled"; fi
}

do_push() {
  need_device || return
  local f d
  ask "local file (drag it in):" f
  f=$(clean_path "$f")
  [ -e "$f" ] || { bad "not found"; return; }
  ask "phone folder (default /sdcard/Download):" d
  d=${d:-/sdcard/Download}
  adb push "$f" "$d/"
}

do_pull() {
  need_device || return
  local r
  ask "phone path (e.g. /sdcard/DCIM/Camera):" r
  [ -z "$r" ] && return
  mkdir -p "$OUT/pulled"
  if adb pull "$r" "$OUT/pulled/"; then ok "saved → $OUT/pulled/"; fi
}

do_log() {
  need_device || return
  local c f
  echo " ${P}1${R}) live   ${P}2${R}) save snapshot"
  ask "choose:" c
  case $c in
    1) echo " ${D}ctrl+c to stop${R}"; adb logcat -v time ;;
    2) f="$OUT/log_$(stamp).txt"; adb logcat -d -v time > "$f"; ok "saved → $f" ;;
    *) bad "cancelled" ;;
  esac
}

do_mirror() {
  need_device || return
  if command -v scrcpy >/dev/null 2>&1; then
    scrcpy
  else
    bad "scrcpy not installed (apt / brew install scrcpy)"
  fi
}

do_reboot() {
  need_device || return
  local c y
  echo " ${P}1${R}) system   ${P}2${R}) recovery   ${P}3${R}) bootloader"
  ask "choose:" c
  [[ "$c" =~ ^[123]$ ]] || { bad "cancelled"; return; }
  ask "reboot now? (y/N)" y
  [[ "$y" =~ ^[Yy]$ ]] || { bad "cancelled"; return; }
  case $c in
    1) adb reboot ;;
    2) adb reboot recovery ;;
    3) adb reboot bootloader ;;
  esac
}

do_shell() { need_device || return; adb shell; }

# ---------- main ----------
if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found. Install Android platform-tools first."
  exit 1
fi
adb start-server >/dev/null 2>&1

while true; do
  banner
  status
  menu
  ask "ripper ›" c || exit 0
  echo
  case $c in
    1)  do_wifi ;;
    2)  do_info ;;
    3)  pick_device ;;
    4)  do_shot ;;
    5)  do_record ;;
    6)  do_install ;;
    7)  do_apps ;;
    8)  do_uninstall ;;
    9)  do_push ;;
    10) do_pull ;;
    11) do_log ;;
    12) do_mirror ;;
    13) do_reboot ;;
    14) do_shell ;;
    15) do_pair ;;
    16) do_disconnect ;;
    0|q) echo " ${D}bye.${R}"; exit 0 ;;
    *)  bad "unknown option" ;;
  esac
  pause
done
