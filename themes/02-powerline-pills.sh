#!/usr/bin/env bash
# claude-code-statusline · 02 Powerline pills
# The same badges, seamlessly joined by arrow separators.
# NEEDS A NERD / POWERLINE-PATCHED FONT for the  separator glyph.
# https://github.com/shyam-pareek/claude-code-statusline
#
# Reads Claude Code status JSON on stdin and prints one status line.

# ── config ──────────────────────────────────────────────
SHOW_PROJECT=true    # leading 📁 project pill
SHOW_COST=true       # trailing $cost pill
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
  printf '⏳%s' "$(_fmt "$1" "$f" | tr 'AMP' 'amp')"
}
T5=$(_rt "$(_j '.rate_limits.five_hour.resets_at // empty')")
T7=$(_rt "$(_j '.rate_limits.seven_day.resets_at // empty')")
COST=$(_j '.cost.total_cost_usd // 0'); COST=$(printf '%.2f' "${COST:-0}" 2>/dev/null); [ -z "$COST" ] && COST='0.00'
ESC=$(printf '\033'); R="${ESC}[0m"; W="${ESC}[38;5;231m"; B="${ESC}[1m"
SEP=$(printf '\356\202\260')   # U+E0B0 powerline right arrow

# bgs: project=60 slate · model=55 purple · ctx=30 teal · 5h=130 orange (time 94) · 7d=24 blue (time 31) · cost=22 green
out=""
if [ "$SHOW_PROJECT" = true ]; then
  out="${out}${ESC}[48;5;60m${W}${B} 📁 ${PROJECT} ${ESC}[38;5;60m${ESC}[48;5;55m${SEP}"
else
  out="${out}${ESC}[48;5;55m"
fi
out="${out}${W}${B} ${MODEL} ${ESC}[38;5;55m${ESC}[48;5;30m${SEP}"
out="${out}${W} ctx ${CTX}% ${ESC}[38;5;30m${ESC}[48;5;130m${SEP}"
out="${out}${W} 5h ${R5}% "
if [ -n "$T5" ]; then
  out="${out}${ESC}[38;5;130m${ESC}[48;5;94m${SEP}${W} ${T5} ${ESC}[38;5;94m${ESC}[48;5;24m${SEP}"
else
  out="${out}${ESC}[38;5;130m${ESC}[48;5;24m${SEP}"
fi
out="${out}${W} 7d ${R7}% "
LAST=24
if [ -n "$T7" ]; then
  out="${out}${ESC}[38;5;24m${ESC}[48;5;31m${SEP}${W} ${T7} "; LAST=31
fi
if [ "$SHOW_COST" = true ]; then
  out="${out}${ESC}[38;5;${LAST}m${ESC}[48;5;22m${SEP}${W} \$${COST} ${ESC}[38;5;22m${ESC}[49m${SEP}"
else
  out="${out}${ESC}[38;5;${LAST}m${ESC}[49m${SEP}"
fi
out="${out}${R}"
printf '%s\n' "$out"
