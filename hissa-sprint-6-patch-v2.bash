#!/usr/bin/env bash
set -euo pipefail

PAGE="src/pages/tools/hissa-calculator.astro"
MAIN="src/scripts/hissa-calculator.js"
CSS="src/styles/hissa-calculator.css"
STAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKUP="backups/hissa-sprint-6-v2-${STAMP}"

echo "=== Hissa Sprint 6 V2 patch ==="

for f in "$PAGE" "$MAIN" "$CSS"; do
  [[ -f "$f" ]] || { echo "ABORT: missing $f"; exit 1; }
done

mkdir -p "$BACKUP"
cp "$PAGE" "$BACKUP/"
cp "$MAIN" "$BACKUP/"
cp "$CSS" "$BACKUP/"
echo "Backup created: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import re

main = Path("src/scripts/hissa-calculator.js")
text = main.read_text(encoding="utf-8")

if "function normalizeHissaDigits" not in text:
    markers = [
        "function createRow()",
        "function getCurrentState()",
        "function saveInputsToState()",
    ]
    pos = next((text.find(m) for m in markers if text.find(m) >= 0), -1)
    if pos < 0:
        raise SystemExit("ABORT: safe insertion point not found.")

    helper = '''
const HissaDigitMap = new Map([
  ["০","0"],["১","1"],["২","2"],["৩","3"],["৪","4"],
  ["৫","5"],["৬","6"],["৭","7"],["৮","8"],["৯","9"],
  ["٠","0"],["١","1"],["٢","2"],["٣","3"],["٤","4"],
  ["٥","5"],["٦","6"],["٧","7"],["٨","8"],["٩","9"],
]);

function normalizeHissaDigits(value) {
  return String(value ?? "").replace(/[০-৯٠-٩]/g, (digit) => {
    return HissaDigitMap.get(digit) ?? digit;
  });
}

'''
    text = text[:pos] + helper + text[pos:]

text = text.replace(
    "current.totalLand = elements.totalLand.value;",
    "current.totalLand = normalizeHissaDigits(elements.totalLand.value);",
    1
)

if "জমি ১৬ আনার বেশি!" not in text:
    patterns = [
        re.compile(
            r'(?P<indent>\s*)const\s+result\s*=\s*'
            r'(?P<body>state\.activeMode\s*===\s*"normal"\s*\?[\s\S]{0,700}?calculateGroupLine\s*\(\s*validatedPayload\s*\)\s*;)',
            re.M,
        ),
        re.compile(
            r'(?P<indent>\s*)const\s+result\s*=\s*'
            r'(?P<body>state\.activeMode\s*===\s*[\'"]normal[\'"][\s\S]{0,900}?calculateGroupLine\s*\(\s*validatedPayload\s*\)\s*;)',
            re.M,
        ),
    ]

    match = next((p.search(text) for p in patterns if p.search(text)), None)
    if not match:
        raise SystemExit(
            "ABORT: calculation block not found. No further files were modified."
        )

    indent = match.group("indent")
    guard = f'''{indent}const totalListedTil = (validatedPayload.rows || []).reduce(
{indent}  (sum, row) =>
{indent}    sum +
{indent}    Number(row.anna || 0) * 4800 +
{indent}    Number(row.gonda || 0) * 240 +
{indent}    Number(row.kora || 0) * 60 +
{indent}    Number(row.kranti || 0) * 20 +
{indent}    Number(row.til || 0),
{indent}  0
{indent});

{indent}if (
{indent}  (state.activeMode === "normal" || state.activeMode === "groupline") &&
{indent}  totalListedTil > 76800
{indent}) {{
{indent}  throw new Error(
{indent}    "জমি ১৬ আনার বেশি! ভালো করে যাচাই করুন। খতিয়ানে ভুল কি না ভালো করে দেখুন!"
{indent}  );
{indent}}

'''
    text = text[:match.start()] + guard + text[match.start():]

main.write_text(text, encoding="utf-8")
print("Calculator JS patched successfully.")
PY

python3 - <<'PY'
from pathlib import Path
import re

page = Path("src/pages/tools/hissa-calculator.astro")
text = page.read_text(encoding="utf-8")

if 'data-mode="metric"' not in text:
    m = re.search(
        r'<button[\s\S]*?data-mode="groupline"[\s\S]*?</button>',
        text, flags=re.I
    )
    if not m:
        raise SystemExit("ABORT: GroupLine button marker not found.")

    metric_button = '''
      <button
        type="button"
        class="hissa-mode-button"
        data-mode="metric"
        role="tab"
        aria-selected="false"
      >
        Metric Mode
      </button>'''
    text = text[:m.end()] + metric_button + text[m.end():]

if "hissa-mode-tabs--spaced" not in text:
    text = text.replace(
        'class="hissa-mode-tabs"',
        'class="hissa-mode-tabs hissa-mode-tabs--spaced"',
        1
    )

m = re.search(
    r'<select[^>]*id="hissa-land-unit"[^>]*>([\s\S]*?)</select>',
    text, flags=re.I
)
if not m:
    raise SystemExit("ABORT: hissa-land-unit select not found.")

body = m.group(1)
for value, label in [
    ("শতক","শতক"),
    ("অযুতাংশ","অযুতাংশ"),
    ("লক্ষাংশ","লক্ষাংশ"),
    ("একর","একর"),
]:
    if f'value="{value}"' not in body:
        body += f'\n        <option value="{value}">{label}</option>'
text = text[:m.start(1)] + body + text[m.end(1):]

if "data-hissa-button-layout" not in text:
    text = text.replace(
        '<div class="hissa-actions">',
        '<div class="hissa-actions" data-hissa-button-layout>',
        1
    )

page.write_text(text, encoding="utf-8")
print("Astro UI patched successfully.")
PY

cat >> "$CSS" <<'CSS'

/* Hissa Sprint 6 V2 UI */
.hissa-mode-tabs--spaced {
  display: flex;
  gap: 10px;
}

.hissa-mode-tabs--spaced .hissa-mode-button {
  flex: 1 1 0;
}

.hissa-actions[data-hissa-button-layout] {
  display: grid;
  grid-template-columns: minmax(100px, 0.32fr) minmax(220px, 1fr);
  gap: 12px;
  align-items: stretch;
}

.hissa-actions[data-hissa-button-layout] #hissa-reset {
  order: 1;
}

.hissa-actions[data-hissa-button-layout] #hissa-calculate {
  order: 2;
}

@media (max-width: 700px) {
  .hissa-mode-tabs--spaced {
    gap: 6px;
  }

  .hissa-actions[data-hissa-button-layout] {
    grid-template-columns: 0.8fr 2.5fr;
  }
}
CSS

echo
echo "=== Hissa tests ==="
node --test tests/hissa/*.test.js

echo
echo "=== Production build ==="
npm run build

echo
echo "SUCCESS: Sprint 6 V2 patch applied."
echo "Backup: $BACKUP"
echo "DO NOT commit/push yet."
