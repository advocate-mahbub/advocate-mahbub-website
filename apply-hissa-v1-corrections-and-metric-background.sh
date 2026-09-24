#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Hissa Calculator V1 — Normal + GroupLine Corrections
# ============================================================
# Purpose:
# 1. Backup current Hissa V1 files
# 2. Apply ONLY the agreed Normal + GroupLine V1 corrections
# 3. Prepare an isolated Metric Mode background
# 4. Do NOT integrate Metric Mode into the existing UI yet
# 5. Do NOT touch unrelated Legal Knowledge files
#
# Run from:
# /workspaces/advocate-mahbub-website
#
# Usage:
#   bash scripts/apply-hissa-v1-corrections-and-metric-background.sh
# ============================================================

ROOT="$(pwd)"
STAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKUP_DIR="$ROOT/backups/hissa-v1-correction-$STAMP"
METRIC_DIR="$ROOT/src/domain/hissa/metric-background"

echo "== Hissa V1 correction script =="
echo "Root: $ROOT"
echo "Backup: $BACKUP_DIR"

if [[ ! -f "$ROOT/package.json" ]]; then
  echo "ERROR: package.json not found. Run this from the Astro project root."
  exit 1
fi

mkdir -p "$BACKUP_DIR"
mkdir -p "$METRIC_DIR"

# ------------------------------------------------------------
# 1. Backup only Hissa-related files before changing anything
# ------------------------------------------------------------
FILES=(
  "src/pages/tools/hissa-calculator.astro"
  "src/scripts/hissa-calculator.js"
  "src/styles/hissa-calculator.css"
  "src/domain/hissa/modes/normal.js"
  "src/domain/hissa/modes/groupline.js"
  "src/domain/hissa/result/explanation.js"
  "src/domain/hissa/result/formatter.js"
  "src/domain/hissa/validation/input.js"
  "src/domain/hissa/validation/notation.js"
  "src/domain/hissa/index.js"
)

for file in "${FILES[@]}"; do
  if [[ -f "$ROOT/$file" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP_DIR/$file"
  fi
done

echo "Backup created."

# ------------------------------------------------------------
# 2. Guard: do not overwrite an existing Metric background
# ------------------------------------------------------------
if find "$METRIC_DIR" -type f -not -name '.gitkeep' -print -quit | grep -q .; then
  echo "ERROR: Metric background already contains files:"
  find "$METRIC_DIR" -type f -print
  echo "No files were overwritten."
  exit 1
fi

# ------------------------------------------------------------
# 3. Isolated Metric Mode background
#    This is intentionally NOT imported by existing Hissa code.
# ------------------------------------------------------------
cat > "$METRIC_DIR/parser.js" <<'EOF'
// Isolated Metric Mode parser.
// Not imported by Normal / GroupLine.
// Supports English and Bengali decimal digits.

const BANGLA_DIGITS = '০১২৩৪৫৬৭৮৯';
const ENGLISH_DIGITS = '0123456789';

export function normalizeMetricNumber(value) {
  if (value === null || value === undefined) return '';

  return String(value)
    .trim()
    .replace(/[০-৯]/g, ch => ENGLISH_DIGITS[BANGLA_DIGITS.indexOf(ch)])
    .replace(/,/g, '');
}

export function parseMetricNumber(value) {
  const normalized = normalizeMetricNumber(value);

  if (normalized === '') return null;
  if (!/^\d+(?:\.\d+)?$/.test(normalized)) return null;

  const number = Number(normalized);
  return Number.isFinite(number) ? number : null;
}
EOF

cat > "$METRIC_DIR/validation.js" <<'EOF'
// Isolated Metric Mode validation.
// V1 structure assumes a 1000-based metric share system.

export const METRIC_TOTAL_SHARE = 1000;

export function validateMetricTotalShare(value) {
  if (value !== METRIC_TOTAL_SHARE) {
    return {
      valid: false,
      message: 'Metric Mode-এ মোট হিস্যা ১০০০ হতে হবে।',
    };
  }

  return { valid: true, message: '' };
}

export function validateMetricRows(rows) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return {
      valid: false,
      message: 'অন্তত একজন শরিকের হিস্যা দিতে হবে।',
    };
  }

  for (const row of rows) {
    if (!row || !Number.isFinite(row.share) || row.share < 0) {
      return {
        valid: false,
        message: 'প্রতিটি শরিকের হিস্যা শূন্য বা তার বেশি হতে হবে।',
      };
    }
  }

  return { valid: true, message: '' };
}
EOF

cat > "$METRIC_DIR/metric.js" <<'EOF'
// ============================================================
// Isolated Metric Mode calculation engine
// ============================================================
// This file is deliberately independent from:
// - Normal Mode
// - GroupLine Mode
// - Astro
// - DOM
// - localStorage
// ============================================================

import { parseMetricNumber } from './parser.js';
import {
  METRIC_TOTAL_SHARE,
  validateMetricTotalShare,
  validateMetricRows,
} from './validation.js';

export function calculateMetric({
  totalLand,
  totalShare = METRIC_TOTAL_SHARE,
  rows = [],
}) {
  const land = parseMetricNumber(totalLand);
  const metricTotal = parseMetricNumber(totalShare);

  if (land === null || land <= 0) {
    throw new Error('মোট জমির পরিমাণ ০-এর বেশি হতে হবে।');
  }

  if (metricTotal === null) {
    throw new Error('মোট হিস্যার পরিমাণ সঠিক নয়।');
  }

  const totalValidation = validateMetricTotalShare(metricTotal);
  if (!totalValidation.valid) {
    throw new Error(totalValidation.message);
  }

  const parsedRows = rows.map((row, index) => ({
    name: String(row?.name ?? '').trim() || `শরিক ${index + 1}`,
    share: parseMetricNumber(row?.share),
  }));

  const rowValidation = validateMetricRows(parsedRows);
  if (!rowValidation.valid) {
    throw new Error(rowValidation.message);
  }

  const listedShare = parsedRows.reduce((sum, row) => sum + row.share, 0);

  if (listedShare !== metricTotal) {
    throw new Error(
      `মোট হিস্যার সঙ্গে শরিকদের হিস্যার যোগফল মিলছে না। বর্তমান যোগফল ${listedShare}।`
    );
  }

  const resultRows = parsedRows.map(row => {
    const percentage = (row.share / metricTotal) * 100;
    const allocatedLand = land * (row.share / metricTotal);

    return {
      name: row.name,
      share: row.share,
      percentage,
      allocatedLand,
    };
  });

  return {
    mode: 'metric',
    totalLand: land,
    totalShare: metricTotal,
    listedShare,
    rows: resultRows,
    allocatedLandTotal: resultRows.reduce(
      (sum, row) => sum + row.allocatedLand,
      0
    ),
  };
}
EOF

cat > "$METRIC_DIR/formatter.js" <<'EOF'
// Isolated Metric Mode formatting helpers.

export function formatMetricShare(value) {
  return Number(value).toLocaleString('bn-BD', {
    maximumFractionDigits: 4,
  });
}

export function formatMetricPercent(value) {
  return `${Number(value).toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 4,
  })}%`;
}
EOF

cat > "$METRIC_DIR/explanation.js" <<'EOF'
// Isolated Metric Mode calculation trace.

export function buildMetricExplanation(result) {
  const lines = [
    `মোট হিস্যা ${result.totalShare.toLocaleString('bn-BD')} ধরা হয়েছে।`,
    `শরিকদের হিস্যার যোগফল ${result.listedShare.toLocaleString('bn-BD')}।`,
    'প্রতিটি শরিকের হিস্যার অনুপাত অনুযায়ী মোট জমির অংশ নির্ধারণ করা হয়েছে।',
  ];

  return lines.join('\n');
}
EOF

cat > "$METRIC_DIR/index.js" <<'EOF'
// Metric Mode background entry point.
// Intentionally NOT imported by the existing Hissa V1 index yet.

export { calculateMetric } from './metric.js';
export { parseMetricNumber, normalizeMetricNumber } from './parser.js';
export {
  METRIC_TOTAL_SHARE,
  validateMetricTotalShare,
  validateMetricRows,
} from './validation.js';
export {
  formatMetricShare,
  formatMetricPercent,
} from './formatter.js';
export { buildMetricExplanation } from './explanation.js';
EOF

cat > "$METRIC_DIR/README.md" <<'EOF'
# Hissa Calculator — Metric Mode Background

This is an isolated V1 background for Metric Mode.

## Current rule

Metric Mode uses a 1000-based total share.

Example:

- Karim = 300
- Rahim = 300
- Jalil = 400
- Total = 1000

The listed shares must add up to 1000.

## Allocation

Individual percentage:

share / 1000

Allocated land:

total land × (share / 1000)

## Important

This module is intentionally NOT integrated into the current Hissa UI.

It does not modify:

- Normal Mode
- GroupLine Mode
- existing Hissa UI
- existing Hissa CSS
- existing Hissa index

Integration should happen only after Metric Mode rules are fully verified.
EOF

# ------------------------------------------------------------
# 4. Normal + GroupLine V1 correction patches
# ------------------------------------------------------------
python3 - <<'PY'
from pathlib import Path

root = Path(".")

# A. Bangla numeral fallback labels
for rel in [
    "src/domain/hissa/modes/normal.js",
    "src/domain/hissa/modes/groupline.js",
]:
    p = root / rel
    if not p.exists():
        continue

    text = p.read_text(encoding="utf-8")

    for i in range(1, 10):
        bn = "০১২৩৪৫৬৭৮৯"[i]
        text = text.replace(f"শরিক {i}", f"শরিক {bn}")
        text = text.replace(f"Group {i}", f"গ্রুপ {bn}")

    p.write_text(text, encoding="utf-8")

# B. User-facing terminology in current Hissa script
p = root / "src/scripts/hissa-calculator.js"
if p.exists():
    text = p.read_text(encoding="utf-8")

    replacements = {
        "Allocation:": "হিস্যার অংশ:",
        "Absolute share:": "দশমিকে অংশ:",
        "Total Listed Share": "মোট শেয়ার",
    }

    for old, new in replacements.items():
        text = text.replace(old, new)

    # Exact agreed blank-total-land message.
    old_candidates = [
        "মোট জমি পরিমাণ ০-এর বেশি হতে হবে।",
        "মোট জমির পরিমাণ ০-এর বেশি হতে হবে।",
    ]

    for old in old_candidates:
        text = text.replace(
            old,
            "উপরে মোট জমির পরিমাণ বসানো হয়নি। পরিমাণ বসিয়ে নিচের “হিসাব করুন” বাটনে আবার চাপুন।"
        )

    p.write_text(text, encoding="utf-8")

# C. Terminology in explanation where these exact labels exist.
p = root / "src/domain/hissa/result/explanation.js"
if p.exists():
    text = p.read_text(encoding="utf-8")
    text = text.replace("Total Listed Share", "মোট শেয়ার")
    text = text.replace("Total Share", "মোট শেয়ার")
    text = text.replace("Allocation", "হিস্যার অংশ")
    text = text.replace("Absolute share", "দশমিকে অংশ")
    p.write_text(text, encoding="utf-8")
PY

# ------------------------------------------------------------
# 5. Show exact changed files
# ------------------------------------------------------------
echo
echo "== Changed Hissa files =="
git status --short -- \
  src/pages/tools/hissa-calculator.astro \
  src/scripts/hissa-calculator.js \
  src/styles/hissa-calculator.css \
  src/domain/hissa \
  "$METRIC_DIR"

echo
echo "== Metric background files =="
find "$METRIC_DIR" -type f | sort

echo
echo "== Backup =="
echo "$BACKUP_DIR"

echo
echo "IMPORTANT:"
echo "No git add / commit / push was performed."
echo "Review the changes, then run the test/build commands separately."
