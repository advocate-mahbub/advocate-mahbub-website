#!/usr/bin/env bash
set -euo pipefail

PAGE="src/pages/tools/hissa-calculator.astro"
MAIN="src/scripts/hissa-calculator.js"
CSS="src/styles/hissa-calculator.css"
STAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKUP="backups/hissa-sprint-6-${STAMP}"

echo "=== Hissa Sprint 6 patch ==="

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

main = Path("src/scripts/hissa-calculator.js")
text = main.read_text(encoding="utf-8")

if "function normalizeHissaDigits" not in text:
    marker = "function createRow()"
    pos = text.find(marker)
    if pos == -1:
        raise SystemExit("ABORT: createRow() marker not found.")

    helper = r'''
const HissaDigitMap = new Map([
  ["০","0"],["১","1"],["২","2"],["৩","3"],["৪","4"],
  ["৫","5"],["৬","6"],["৭","7"],["৮","8"],["৯","9"],
  ["٠","0"],["١","1"],["٢","2"],["٣","3"],["٤","4"],
  ["٥","5"],["٦","6"],["٧","7"],["٨","8"],["٩","9"],
]);

function normalizeHissaDigits(value) {
  return String(value ?? "").replace(/[০-৯٠-٩]/g, d => HissaDigitMap.get(d) ?? d);
}

function parseHissaNumber(value) {
  const normalized = normalizeHissaDigits(value).replace(/[,\s]/g, "");
  if (normalized === "") return NaN;
  return Number(normalized);
}

function landUnitToShotok(unit) {
  const key = String(unit ?? "").trim();
  const map = {
    "একর": 100,
    "শতক": 1,
    "অযুতাংশ": 0.01,
    "লক্ষাংশ": 0.0001,
  };
  return map[key] ?? 1;
}

function convertLandUnit(value, fromUnit, toUnit) {
  return Number(value) * landUnitToShotok(fromUnit) / landUnitToShotok(toUnit);
}

'''
    text = text[:pos] + helper + text[pos:]

old = "current.totalLand = elements.totalLand.value;"
if old in text:
    text = text.replace(
        old,
        "current.totalLand = normalizeHissaDigits(elements.totalLand.value);",
        1
    )

if "জমি ১৬ আনার বেশি!" not in text:
    marker = 'const result =\n    state.activeMode === "normal"'
    pos = text.find(marker)
    if pos == -1:
        raise SystemExit("ABORT: calculation result marker not found.")

    guard = r'''const totalListedTil = (validatedPayload.rows || []).reduce(
    (sum, row) =>
      sum +
      Number(row.anna || 0) * 4800 +
      Number(row.gonda || 0) * 240 +
      Number(row.kora || 0) * 60 +
      Number(row.kranti || 0) * 20 +
      Number(row.til || 0),
    0
  );

  if (
    (state.activeMode === "normal" || state.activeMode === "groupline") &&
    totalListedTil > 76800
  ) {
    throw new Error(
      "জমি ১৬ আনার বেশি! ভালো করে যাচাই করুন। খতিয়ানে ভুল কি না ভালো করে দেখুন!"
    );
  }

  '''
    text = text[:pos] + guard + text[pos:]

main.write_text(text, encoding="utf-8")
print("Main calculator patched.")
PY

python3 - <<'PY'
from pathlib import Path

page = Path("src/pages/tools/hissa-calculator.astro")
text = page.read_text(encoding="utf-8")

if "hissa-mode-tabs--spaced" not in text:
    text = text.replace(
        'class="hissa-mode-tabs"',
        'class="hissa-mode-tabs hissa-mode-tabs--spaced"',
        1
    )

needle = '<select id="hissa-land-unit"'
start = text.find(needle)
if start == -1:
    raise SystemExit("ABORT: hissa-land-unit select not found.")
end = text.find("</select>", start)
if end == -1:
    raise SystemExit("ABORT: hissa-land-unit closing select not found.")

body = text[start:end]
for value, label in [
    ("শতক","শতক"),
    ("অযুতাংশ","অযুতাংশ"),
    ("লক্ষাংশ","লক্ষাংশ"),
    ("একর","একর"),
]:
    if f'value="{value}"' not in body:
        body += f'\n  <option value="{value}">{label}</option>'

text = text[:start] + body + text[end:]

if "data-hissa-button-layout" not in text:
    text = text.replace(
        '<div class="hissa-actions"',
        '<div class="hissa-actions" data-hissa-button-layout',
        1
    )

page.write_text(text, encoding="utf-8")
print("Astro page patched.")
PY

cat >> "$CSS" <<'CSS'

/* Hissa Sprint 6 UI */
.hissa-mode-tabs--spaced {
  display: flex;
  gap: 10px;
}

.hissa-mode-tabs--spaced .hissa-mode-button {
  flex: 1 1 0;
}

.hissa-actions[data-hissa-button-layout] {
  display: grid;
  grid-template-columns: minmax(100px, 0.28fr) minmax(220px, 1fr);
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
echo "=== Tests ==="
node --test tests/hissa/*.test.js

echo
echo "=== Production build ==="
npm run build

echo
echo "SUCCESS: Sprint 6 patch applied."
echo "Backup: $BACKUP"
echo "Do NOT commit/push until browser review."
