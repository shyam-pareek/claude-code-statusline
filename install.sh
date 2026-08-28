#!/usr/bin/env bash
# claude-code-statusline · installer
# Usage:
#   Interactive : curl -fsSL https://raw.githubusercontent.com/shyam-pareek/claude-code-statusline/main/install.sh | bash
#   Pick a theme: curl -fsSL .../install.sh | THEME=4 bash
#   From a clone: ./install.sh   (or THEME=4 ./install.sh)
#
# Optional env: THEME=1..7  SHOW_PROJECT=false  SHOW_COST=false
set -u

REPO="shyam-pareek/claude-code-statusline"
RAW="https://raw.githubusercontent.com/${REPO}/main"
INSTALL_DIR="${HOME}/.claude/statusline"
DEST="${INSTALL_DIR}/statusline.sh"
SETTINGS="${HOME}/.claude/settings.json"

c_bold=$(printf '\033[1m'); c_dim=$(printf '\033[2m')
c_grn=$(printf '\033[38;5;82m'); c_red=$(printf '\033[38;5;196m')
c_cyn=$(printf '\033[38;5;51m'); c_rst=$(printf '\033[0m')
say(){ printf '%s\n' "$*"; }
die(){ printf '%s%s%s\n' "$c_red" "$*" "$c_rst" >&2; exit 1; }

# themes: "num|file|title|description"
THEMES="
1|01-pills|Pills|Solid rounded pills, white text; clean and readable
2|02-powerline-pills|Powerline pills|Seamless arrow-joined pills (needs a Nerd Font)
3|03-vivid-labels|Vivid labels|Bright labels; numbers shade green→amber→red by usage
4|04-emoji-neon|Emoji neon|Emoji markers + bold neon percentages
5|05-neon-separators|Neon separators|Diamond-separated fields, bright accents
6|06-two-tone-pills|Two-tone pills|Bright pills with dark text; the loudest set
7|07-gradient-sweep|Gradient sweep|Hue glides pink→purple→blue→green
"

field(){ printf '%s\n' "$THEMES" | awk -F'|' -v n="$1" -v c="$2" '$1==n{print $c}'; }

command -v jq >/dev/null 2>&1 || die "jq is required (both installer and themes use it).
  macOS:  brew install jq
  Debian: sudo apt-get install -y jq
  Fedora: sudo dnf install -y jq"

say ""
say "${c_bold}${c_cyn}  claude-code-statusline${c_rst}${c_dim}  ·  colorful status lines for Claude Code${c_rst}"
say ""

# ---- choose theme ----
if [ -n "${THEME:-}" ]; then
  case "$THEME" in 1|2|3|4|5|6|7) : ;; *) die "THEME must be 1-7 (got: $THEME)";; esac
else
  printf '%s\n' "$THEMES" | awk -F'|' 'NF{printf "  %s  %-18s %s\n",$1,$3,$4}'
  say ""
  if [ ! -r /dev/tty ]; then
    die "No terminal for the menu. Re-run with a theme number, e.g.:  curl -fsSL ${RAW}/install.sh | THEME=1 bash"
  fi
  printf '%sChoose a theme [1-7]:%s ' "$c_bold" "$c_rst" > /dev/tty
  read -r THEME < /dev/tty
  case "$THEME" in 1|2|3|4|5|6|7) : ;; *) die "Not a valid choice: $THEME";; esac
fi

FILE=$(field "$THEME" 2)
TITLE=$(field "$THEME" 3)

# ---- resolve source (local clone or download) ----
SELFDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo "")
mkdir -p "$INSTALL_DIR"
if [ -n "$SELFDIR" ] && [ -f "${SELFDIR}/themes/${FILE}.sh" ]; then
  cp "${SELFDIR}/themes/${FILE}.sh" "$DEST"
else
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${RAW}/themes/${FILE}.sh" -o "$DEST" || die "Download failed: ${RAW}/themes/${FILE}.sh"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$DEST" "${RAW}/themes/${FILE}.sh" || die "Download failed: ${RAW}/themes/${FILE}.sh"
  else
    die "Need curl or wget to download the theme."
  fi
fi
chmod +x "$DEST"

# ---- optional toggles ----
if [ "${SHOW_PROJECT:-}" = "false" ]; then
  sed 's/^SHOW_PROJECT=true/SHOW_PROJECT=false/' "$DEST" > "$DEST.tmp" && mv "$DEST.tmp" "$DEST"
fi
if [ "${SHOW_COST:-}" = "false" ]; then
  sed 's/^SHOW_COST=true/SHOW_COST=false/' "$DEST" > "$DEST.tmp" && mv "$DEST.tmp" "$DEST"
fi
chmod +x "$DEST"

# ---- merge into settings.json (back up first, touch only .statusLine) ----
CMD="bash ${DEST}"
tmp=$(mktemp)
if [ -f "$SETTINGS" ]; then
  jq -e . "$SETTINGS" >/dev/null 2>&1 || die "$SETTINGS is not valid JSON. Fix or move it, then re-run."
  bak="${SETTINGS}.bak-$(date +%Y%m%d%H%M%S)"
  cp "$SETTINGS" "$bak"
  jq --arg cmd "$CMD" '.statusLine = {type:"command", command:$cmd}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  say "${c_dim}  backed up existing settings → ${bak}${c_rst}"
else
  mkdir -p "$(dirname "$SETTINGS")"
  jq -n --arg cmd "$CMD" '{statusLine:{type:"command", command:$cmd}}' > "$SETTINGS"
fi

say ""
say "${c_grn}  ✓ Installed:${c_rst} ${c_bold}${TITLE}${c_rst}"
say "${c_dim}    theme  → ${DEST}${c_rst}"
say "${c_dim}    config → ${SETTINGS} (.statusLine)${c_rst}"
if [ "$THEME" = "2" ]; then
  say "${c_dim}    note   → Powerline pills need a Nerd Font (https://www.nerdfonts.com) for the arrows.${c_rst}"
fi
say ""
say "  Open a new Claude Code session (or restart) to see it."
say "  Switch anytime:  re-run this installer and pick another number."
say ""
