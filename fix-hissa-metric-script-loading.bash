#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
PAGE="src/pages/tools/hissa-calculator.astro"
METRIC_JS="src/scripts/hissa-metric-ui.js"
STAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKUP="backups/fix-metric-script-loading-${STAMP}"

echo "Hissa Metric script-loading fix"
echo "Working directory: ${ROOT}"

if [[ ! -f "$PAGE" ]]; then
  echo "ABORT: $PAGE not found."
  exit 1
fi

if [[ ! -f "$METRIC_JS" ]]; then
  echo "ABORT: $METRIC_JS not found."
  echo "The Metric UI file must exist before this patch."
  exit 1
fi

mkdir -p "$BACKUP"
cp "$PAGE" "$BACKUP/hissa-calculator.astro"
cp "$METRIC_JS" "$BACKUP/hissa-metric-ui.js"
echo "Backup created: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import re

page = Path("src/pages/tools/hissa-calculator.astro")
text = page.read_text(encoding="utf-8")

# Remove the public-URL style Metric UI script reference, if present.
patterns = [
    r'<script\s+src=["\']/scripts/hissa-metric-ui\.js["']\s*>\s*</script>',
    r'<script\s+src=["\']/scripts/hissa-metric-ui\.js["']\s*/>',
]

for pattern in patterns:
    text, _ = re.subn(pattern, "", text, flags=re.I)

# Add a bundled Astro script once. This lets Astro resolve src/scripts/
# instead of treating the file as a public/static asset.
marker = '<script type="module">\n  import "../../scripts/hissa-metric-ui.js";\n</script>'

if "import "../../scripts/hissa-metric-ui.js";" not in text:
    # Put it immediately before the first closing body tag when possible.
    if "</body>" in text:
        text = text.replace("</body>", f"{marker}\n</body>", 1)
    else:
        text = text.rstrip() + "\n\n" + marker + "\n"

page.write_text(text, encoding="utf-8")
PY

echo "Patched: $PAGE"
echo
echo "Checking the Metric UI reference..."
grep -n -A2 -B2 'hissa-metric-ui.js' "$PAGE" || true

echo
echo "Running Hissa tests..."
node --test tests/hissa/*.test.js

echo
echo "Running production build..."
npm run build

echo
echo "SUCCESS"
echo "Metric script-loading patch completed."
echo "Backup: $BACKUP"
echo
echo "Do NOT commit yet."
echo "Open the calculator in the browser and verify:"
echo "  Normal Mode"
echo "  GroupLine Mode"
echo "  Metric Mode"
