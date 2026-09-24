#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspaces/advocate-mahbub-website"
cd "$ROOT"

STAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKUP_DIR="backups/hissa-metric-button-only-$STAMP"
mkdir -p "$BACKUP_DIR"

cp src/pages/tools/hissa-calculator.astro "$BACKUP_DIR/hissa-calculator.astro"
cp src/styles/hissa-calculator.css "$BACKUP_DIR/hissa-calculator.css"

python3 - <<'PY'
from pathlib import Path

astro = Path("src/pages/tools/hissa-calculator.astro")
css = Path("src/styles/hissa-calculator.css")

text = astro.read_text(encoding="utf-8")

if 'data-mode="metric"' in text:
    print("Metric button already exists. No Astro change needed.")
else:
    marker = (
        '      <button\n'
        '        type="button"\n'
        '        class="hissa-mode-button"\n'
        '        data-mode="groupline"\n'
        '        role="tab"\n'
        '        aria-selected="false"\n'
        '      >\n'
        '        GroupLine Mode\n'
        '      </button>'
    )

    if marker not in text:
        raise SystemExit(
            "ABORT: exact GroupLine button block was not found."
        )

    metric = marker + (
        '\n\n'
        '      <button\n'
        '        type="button"\n'
        '        class="hissa-mode-button"\n'
        '        data-mode="metric"\n'
        '        role="tab"\n'
        '        aria-selected="false"\n'
        '      >\n'
        '        Metric Mode\n'
        '      </button>'
    )

    text = text.replace(marker, metric, 1)
    astro.write_text(text, encoding="utf-8")
    print("Metric Mode button inserted.")

css_text = css.read_text(encoding="utf-8")

if ".hissa-mode-switch" in css_text and "repeat(3" not in css_text:
    css_text += (
        '\n\n'
        '/* Metric Mode: three-button mode selector */\n'
        '.hissa-mode-switch {\n'
        '  grid-template-columns: repeat(3, minmax(0, 1fr));\n'
        '}\n'
        '\n'
        '@media (max-width: 640px) {\n'
        '  .hissa-mode-switch {\n'
        '    grid-template-columns: 1fr;\n'
        '  }\n'
        '}\n'
    )
    css.write_text(css_text, encoding="utf-8")
    print("Mode selector adjusted for three buttons.")
PY

echo
echo "Running production build..."
npm run build

echo
echo "SUCCESS"
echo "Backup: $BACKUP_DIR"
echo "Refresh the Hissa Calculator page."
