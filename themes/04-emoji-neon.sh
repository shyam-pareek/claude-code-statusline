#!/usr/bin/env bash
# claude-code-statusline · 04 Emoji neon
# Emoji markers with bright, bold percentages.
# Works in ANY terminal (that renders emoji).
# https://github.com/shyam-pareek/claude-code-statusline
#
# Reads Claude Code status JSON on stdin and prints one status line.

# ── config ──────────────────────────────────────────────
SHOW_PROJECT=true    # leading 📁 project name
SHOW_COST=true       # trailing 💰$cost
# ────────────────────────────────────────────────────────

command -v jq >/dev/null 2>&1 || { printf 'statusline: jq not found\n'; exit 0; }
INPUT=$(cat)
printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1 || INPUT='{}'
_j(){ printf '%s' "$INPUT" | jq -r "$1" 2>/dev/null; }
PROJDIR=$(_j '.workspace.current_dir // .workspace.project_dir // .cwd // ""')
if [ -n "$PROJDIR" ]; then PROJECT=$(basename "$PROJDIR"); else PROJECT="?"; fi
MODEL=$(_j '.model.display_name // "?"')
CTX=$(_j '(.context_window.used_percentage // 0) | floor')
R5=$(_j '(.rate_limits.five_hour.used_percentage // 0) | floor')
R7=$(_j '(.rate_limits.seven_day.used_percentage // 0) | floor')
# Rate-limit reset times (epoch secs -> local clock; day shown when not today). BSD + GNU date.
_fmt(){ date -r "$1" "+$2" 2>/dev/null || date -d "@$1" "+$2" 2>/dev/null; }
_rt(){
  case "$1" in ''|*[!0-9]*) return;; esac
  local f='%-I:%M%p'
  [ "$(_fmt "$1" %F)" = "$(date +%F)" ] || f="%a $f"
  printf ' · %s' "$(_fmt "$1" "$f" | tr 'AMP' 'amp')"
}
T5=$(_rt "$(_j '.rate_limits.five_hour.resets_at // empty')")
T7=$(_rt "$(_j '.rate_limits.seven_day.resets_at // empty')")
COST=$(_j '.cost.total_cost_usd // 0'); COST=$(printf '%.2f' "${COST:-0}" 2>/dev/null); [ -z "$COST" ] && COST='0.00'
ESC=$(printf '\033'); R="${ESC}[0m"; B="${ESC}[1m"
uc(){ if [ "$1" -ge 80 ] 2>/dev/null; then echo 196; elif [ "$1" -ge 50 ] 2>/dev/null; then echo 214; else echo 82; fi; }

S="  "
out="${ESC}[38;5;201m${B}🤖 ${MODEL}${R}"
[ "$SHOW_PROJECT" = true ] && out="📁 ${ESC}[38;5;231m${B}${PROJECT}${R}${S}${out}"
out="${out}${S}🧠 ${ESC}[38;5;$(uc "$CTX")m${B}${CTX}%${R}"
out="${out}${S}⏳ ${ESC}[38;5;$(uc "$R5")m${B}${R5}%${T5}${R}"
out="${out}${S}📅 ${ESC}[38;5;$(uc "$R7")m${B}${R7}%${T7}${R}"
[ "$SHOW_COST" = true ] && out="${out}${S}💰${ESC}[38;5;118m${B}\$${COST}${R}"
printf '%s\n' "$out"
