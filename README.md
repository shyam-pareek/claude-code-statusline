# claude-code-statusline

Seven colorful, drop-in **status lines** for [Claude Code](https://claude.com/claude-code) — installed with one command.

Each one shows, at a glance:

```
📁 project · model · ctx% · 5h% · 7d% · $cost
```

| field | meaning |
|-------|---------|
| `📁 project` | current working directory (basename) |
| `model` | active model (e.g. Opus 5) |
| `ctx%` | context window used |
| `5h%` | 5-hour rate-limit window used |
| `7d%` | 7-day rate-limit window used |
| `$cost` | session cost so far |

![License: MIT](https://img.shields.io/badge/License-MIT-informational)
![Shell](https://img.shields.io/badge/shell-bash-121011)
![Dependency: jq](https://img.shields.io/badge/needs-jq-blue)

---

## Quick install

```sh
curl -fsSL https://raw.githubusercontent.com/shyam-pareek/claude-code-statusline/main/install.sh | bash
```

You'll get a menu to pick a theme. To skip the menu (e.g. in a pipe), pass a number:

```sh
curl -fsSL https://raw.githubusercontent.com/shyam-pareek/claude-code-statusline/main/install.sh | THEME=4 bash
```

Open a new Claude Code session (or restart) and the status line appears. Switch themes anytime by re-running the installer.

---

## The themes

### 1 · Pills — `THEME=1`
Solid rounded pills, white text. Clean and readable.

![Pills](assets/01-pills.svg)

### 2 · Powerline pills — `THEME=2`
Seamless arrow-joined segments. **Needs a [Nerd Font](https://www.nerdfonts.com)** for the arrows.

![Powerline pills](assets/02-powerline-pills.svg)

### 3 · Vivid labels — `THEME=3`
A bright label per metric; the numbers themselves shade **green → amber → red** as usage climbs.

![Vivid labels](assets/03-vivid-labels.svg)

### 4 · Emoji neon — `THEME=4`
Emoji markers with bold, neon percentages.

![Emoji neon](assets/04-emoji-neon.svg)

### 5 · Neon separators — `THEME=5`
Bright model, colored labels, dim diamond separators between fields.

![Neon separators](assets/05-neon-separators.svg)

### 6 · Two-tone pills — `THEME=6`
Bright backgrounds with dark text — maximum presence, the loudest set.

![Two-tone pills](assets/06-two-tone-pills.svg)

### 7 · Gradient sweep — `THEME=7`
Hue glides pink → purple → blue → green across the whole line.

![Gradient sweep](assets/07-gradient-sweep.svg)

> Preview shows a sample project. On your machine the fields reflect your real session.

---

## Requirements

- **[Claude Code](https://claude.com/claude-code)** — the status line is a Claude Code feature.
- **[jq](https://jqlang.github.io/jq/)** — parses the status JSON.
  `brew install jq` · `sudo apt-get install -y jq` · `sudo dnf install -y jq`
- **A Nerd Font** — only for theme 2 (Powerline pills), for the arrow glyphs.
- A terminal with **256-color** support (virtually all modern terminals).

---

## Try before you install

Clone and preview all seven with sample data:

```sh
git clone https://github.com/shyam-pareek/claude-code-statusline
cd claude-code-statusline
./preview.sh
```

Then install your pick from the clone:

```sh
./install.sh            # interactive
THEME=4 ./install.sh    # or straight to a theme
```

---

## Customize

Each theme is a single self-contained script with a small config block at the top:

```sh
# ── config ──
SHOW_PROJECT=true    # leading 📁 project name
SHOW_COST=true       # trailing $cost
```

Set either to `false` and re-run — or let the installer do it:

```sh
SHOW_PROJECT=false SHOW_COST=false ./install.sh
```

Colors are plain [xterm-256 codes](https://www.ditig.com/256-colors-cheat-sheet) (`38;5;N` foreground, `48;5;N` background) — edit the numbers in `~/.claude/statusline/statusline.sh` to taste.

---

## What the installer does

1. Checks that `jq` is present.
2. Copies your chosen theme to `~/.claude/statusline/statusline.sh`.
3. Backs up `~/.claude/settings.json` to `settings.json.bak-<timestamp>` (if it exists).
4. Sets **only** the `.statusLine` key via `jq` — every other setting is left untouched:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline/statusline.sh"
  }
}
```

## Uninstall

```sh
tmp=$(mktemp); jq 'del(.statusLine)' ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
rm -rf ~/.claude/statusline
```

(or just restore one of the `settings.json.bak-*` backups.)

---

## How it works

Claude Code feeds a JSON blob about the current session to your status-line command on **stdin**; the command prints **one line** to stdout. These themes read fields like `.workspace.current_dir`, `.model.display_name`, `.context_window.used_percentage`, `.rate_limits.five_hour.used_percentage`, `.rate_limits.seven_day.used_percentage`, and `.cost.total_cost_usd`, then paint them with ANSI colors. Missing fields degrade gracefully (`?` / `0%` / `$0.00`).

See the Claude Code [status line docs](https://docs.claude.com/en/docs/claude-code/statusline) for the full schema.

---

## Contributing

New color schemes welcome — copy any `themes/NN-*.sh`, restyle the render section, keep the config block and the graceful-fallback preamble, and add a preview. PRs and issues open.

## License

[MIT](LICENSE) © 2026 Shyam Pareek
