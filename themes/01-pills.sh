#!/usr/bin/env bash
# claude-code-statusline · 01 Pills
# Solid color badges, one hue per metric — works in ANY terminal.
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
COST=$(_j '.cost.total_cost_usd // 0'); COST=$(printf '%.2f' "${COST:-0}" 2>/dev/null); [ -z "$COST" ] && COST='0.00'
ESC=$(printf '\033'); R="${ESC}[0m"; W="${ESC}[38;5;231m"; B="${ESC}[1m"

out=""
[ "$SHOW_PROJECT" = true ] && out="${out}${ESC}[48;5;60m${W}${B} 📁 ${PROJECT} ${R} "
out="${out}${ESC}[48;5;55m${W}${B} ${MODEL} ${R} "
out="${out}${ESC}[48;5;30m${W} ctx ${CTX}% ${R} "
out="${out}${ESC}[48;5;130m${W} 5h ${R5}% ${R} "
out="${out}${ESC}[48;5;24m${W} 7d ${R7}% ${R}"
[ "$SHOW_COST" = true ] && out="${out} ${ESC}[48;5;22m${W} \$${COST} ${R}"
printf '%s\n' "$out"
