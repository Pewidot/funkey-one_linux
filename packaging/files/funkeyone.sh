#!/usr/bin/env bash
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"

find_home() {
  [ -n "$FUNKEY_HOME" ] && { echo "$FUNKEY_HOME"; return; }
  local c
  for c in \
      "$(xdg-user-dir DOCUMENTS 2>/dev/null)/U.B. Funkeys" \
      "$HOME/Documents/U.B. Funkeys" \
      "$HOME/Dokumente/U.B. Funkeys"; do
    [ -d "$c/RadicaGame" ] && { echo "$c"; return; }
  done
}
FUNKEY_HOME="$(find_home)"
if [ -z "$FUNKEY_HOME" ] || [ ! -d "$FUNKEY_HOME/RadicaGame" ]; then
  echo "error: could not find the U.B. Funkeys install." >&2
  echo "       run setup.sh first, or set FUNKEY_HOME to the 'U.B. Funkeys' dir." >&2
  exit 1
fi
GAME_DIR="$FUNKEY_HOME/RadicaGame"

BRIDGE_DIR="${FUNKEY_BRIDGE_DIR:-}"
if [ -z "$BRIDGE_DIR" ] || [ ! -x "$BRIDGE_DIR/funkeyusbd" ]; then
  for cand in "$HERE/winebridge" "$HOME/.local/share/funkeyone/winebridge"; do
    [ -x "$cand/funkeyusbd" ] && { BRIDGE_DIR="$cand"; break; }
  done
fi
BRIDGE_DIR="${BRIDGE_DIR:-$HERE/winebridge}"
export FUNKEY_USB_PORT="${FUNKEY_USB_PORT:-47288}"
export WINEDLLOVERRIDES="ninput=n,b${WINEDLLOVERRIDES:+;$WINEDLLOVERRIDES}"

USBD_PID=
if [ -x "$BRIDGE_DIR/funkeyusbd" ]; then
  pkill -f "$BRIDGE_DIR/funkeyusbd" 2>/dev/null || true
  "$BRIDGE_DIR/funkeyusbd" >/dev/null 2>&1 &
  USBD_PID=$!
fi
cleanup(){
  pkill -f "MegaByte.exe" 2>/dev/null || true
  [ -n "${USBD_PID:-}" ] && kill "$USBD_PID" 2>/dev/null
  return 0
}
trap cleanup EXIT INT TERM

# The game starts MegaByte.exe -MBRun itself (when its Hub setting is on) and
# MegaByte inherits FUNKEY_USB_PORT, so it reaches funkeyusbd. Don't start a
# second copy here: two readers fight over the hub and the game ends up
# showing "connect the hub".

cd "$GAME_DIR"
wine FunkeyOne.exe "$@"
