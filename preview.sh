#!/usr/bin/env bash
# claude-code-statusline · preview all themes with sample data
# Run from a clone:  ./preview.sh
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
command -v jq >/dev/null 2>&1 || { printf 'preview: jq is required (brew install jq / apt-get install jq)\n' >&2; exit 1; }

# Sample status payload (generic demo project).
SAMPLE='{"workspace":{"current_dir":"/home/dev/my-app"},"model":{"display_name":"Opus 5"},"context_window":{"used_percentage":88.4},"rate_limits":{"five_hour":{"used_percentage":91.2},"seven_day":{"used_percentage":64.7}},"cost":{"total_cost_usd":11.2}}'

printf '\n  \033[1mclaude-code-statusline\033[0m  \033[2m— preview (sample: my-app · Opus 5)\033[0m\n\n'
for f in "$DIR"/themes/*.sh; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .sh)
  printf '  \033[2m%s\033[0m\n  ' "$name"
  printf '%s' "$SAMPLE" | bash "$f"
  printf '\n'
done
printf '  \033[2mInstall one:  ./install.sh   (or  THEME=4 ./install.sh)\033[0m\n\n'
