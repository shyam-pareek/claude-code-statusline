#!/usr/bin/env bash
# claude-code-statusline · updater
# Re-downloads your installed theme and keeps your SHOW_PROJECT / SHOW_COST choices.
# Does not touch settings.json.
#
# Usage:
#   ~/.claude/statusline/update.sh
#   curl -fsSL https://raw.githubusercontent.com/shyam-pareek/claude-code-statusline/main/update.sh | bash
# Optional: THEME=1..7 to switch theme while updating.
set -u

REPO="shyam-pareek/claude-code-statusline"
RAW="https://raw.githubusercontent.com/${REPO}/main"
INSTALL_DIR="${HOME}/.claude/statusline"
DEST="${INSTALL_DIR}/statusline.sh"

die(){ printf 'update: %s\n' "$*" >&2; exit 1; }

FILES="01-pills 02-powerline-pills 03-vivid-labels 04-emoji-neon 05-neon-separators 06-two-tone-pills 07-gradient-sweep"

[ -f "$DEST" ] || die "no installed theme at $DEST. Run the installer first:
  curl -fsSL ${RAW}/install.sh | bash"

# ---- which theme? env override > marker file > header of installed script ----
N="${THEME:-}"
[ -z "$N" ] && [ -f "${INSTALL_DIR}/.theme" ] && N=$(tr -d '[:space:]' < "${INSTALL_DIR}/.theme")
if [ -z "$N" ]; then
  N=$(sed -n '2s/^# claude-code-statusline · \([0-9][0-9]\).*/\1/p' "$DEST" | sed 's/^0//')
fi
case "$N" in 1|2|3|4|5|6|7) : ;; *) die "could not tell which theme is installed. Re-run with THEME=<1-7>.";; esac
FILE=$(echo "$FILES" | tr ' ' '\n' | sed -n "${N}p")

# ---- remember current toggles ----
SP=$(sed -n 's/^SHOW_PROJECT=\([a-z]*\).*/\1/p' "$DEST" | head -1)
SC=$(sed -n 's/^SHOW_COST=\([a-z]*\).*/\1/p' "$DEST" | head -1)

# ---- download to a temp file, sanity-check, then swap in ----
tmp=$(mktemp)
trap 'rm -f "$tmp" "$tmp.2"' EXIT
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "${RAW}/themes/${FILE}.sh" -o "$tmp" || die "download failed: ${RAW}/themes/${FILE}.sh"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$tmp" "${RAW}/themes/${FILE}.sh" || die "download failed: ${RAW}/themes/${FILE}.sh"
else
  die "need curl or wget"
fi
head -1 "$tmp" | grep -q '^#!' || die "downloaded file does not look like a script; keeping your current theme."

[ "$SP" = "false" ] && { sed 's/^SHOW_PROJECT=true/SHOW_PROJECT=false/' "$tmp" > "$tmp.2" && mv "$tmp.2" "$tmp"; }
[ "$SC" = "false" ] && { sed 's/^SHOW_COST=true/SHOW_COST=false/' "$tmp" > "$tmp.2" && mv "$tmp.2" "$tmp"; }

if cmp -s "$tmp" "$DEST"; then
  echo "Already up to date (theme ${N}: ${FILE})."
else
  cp "$DEST" "${DEST}.bak"
  cat "$tmp" > "$DEST"; chmod +x "$DEST"
  echo "Updated theme ${N} (${FILE}). Previous copy saved as ${DEST}.bak"
  echo "Open a new Claude Code session to see it."
fi
echo "$N" > "${INSTALL_DIR}/.theme"
