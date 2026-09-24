#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspaces/advocate-mahbub-website"
cd "$ROOT"

STAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKUP_DIR="backups/hissa-sprint-4-metric-core-$STAMP"
mkdir -p "$BACKUP_DIR"

for f in \
  src/domain/hissa/index.js \
  src/domain/hissa/modes/normal.js \
  src/domain/hissa/modes/groupline.js \
  src/domain/hissa/validation/input.js
do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
    cp "$f" "$BACKUP_DIR/$f"
  fi
done

mkdir -p src/domain/hissa/modes
mkdir -p src/domain/hissa/validation
mkdir -p src/domain/hissa/input
mkdir -p tests/hissa

cat > src/domain/hissa/input/parser.js <<'JS'
const DIGIT_MAP = new Map([
  ["০", "0"], ["১", "1"], ["২", "2"], ["৩", "3"], ["৪", "4"],
  ["৫", "5"], ["৬", "6"], ["৭", "7"], ["৮", "8"], ["৯", "9"],

  // Arabic-Indic digits
  ["٠", "0"], ["١", "1"], ["٢", "2"], ["٣", "3"], ["٤", "4"],
  ["٥", "5"], ["٦", "6"], ["٧", "7"], ["٨", "8"], ["٩", "9"],

  // Extended Arabic-Indic digits
  ["۰", "0"], ["۱", "1"], ["۲", "2"], ["۳", "3"], ["۴", "4"],
  ["۵", "5"], ["۶", "6"], ["۷", "7"], ["۸", "8"], ["۹", "9"],
]);

export function normalizeDigits(value) {
  return String(value ?? "")
    .replace(/[০-৯٠-٩۰-۹]/g, (digit) => DIGIT_MAP.get(digit) ?? digit);
}

export function parseFlexibleInteger(value, {
  allowBlank = false,
  min = 0,
  max = Number.MAX_SAFE_INTEGER,
} = {}) {
  const normalized = normalizeDigits(value).trim();

  if (!normalized) {
    if (allowBlank) return null;
    throw new Error("সংখ্যার ঘরটি পূরণ করুন।");
  }

  if (!/^\d+$/.test(normalized)) {
    throw new Error("শুধু সংখ্যা ব্যবহার করুন।");
  }

  const parsed = Number(normalized);

  if (!Number.isSafeInteger(parsed)) {
    throw new Error("সংখ্যাটি গ্রহণযোগ্য সীমার মধ্যে নেই।");
  }

  if (parsed < min || parsed > max) {
    throw new Error(`সংখ্যাটি ${min} থেকে ${max}-এর মধ্যে হতে হবে।`);
  }

  return parsed;
}
JS

cat > src/domain/hissa/validation/metric.js <<'JS'
import { parseFlexibleInteger } from "../input/parser.js";

export const METRIC_TOTAL = 1000;

export function validateMetricRow(row, index = 0) {
  const label =
    String(row?.name ?? "").trim() ||
    `শরিক ${String(index + 1)}`;

  const share = parseFlexibleInteger(row?.share, {
    allowBlank: false,
    min: 0,
    max: METRIC_TOTAL,
  });

  return {
    id: row?.id ?? `metric-${index + 1}`,
    name: label,
    share,
  };
}

export function validateMetricRows(rows) {
  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error("কমপক্ষে একজন শরিক দিতে হবে।");
  }

  const validatedRows = rows.map(validateMetricRow);

  const totalShare = validatedRows.reduce(
    (sum, row) => sum + row.share,
    0
  );

  if (totalShare > METRIC_TOTAL) {
    throw new Error(
      "মোট হিস্যা ১০০০-এর বেশি হয়েছে। ইনপুটে কোথাও ভুল থাকতে পারে। খতিয়ান বা মূল নথির তথ্য আবার যাচাই করুন।"
    );
  }

  if (totalShare <= 0) {
    throw new Error("মোট হিস্যা ০ হতে পারে না।");
  }

  return {
    rows: validatedRows,
    totalShare,
    maxShare: METRIC_TOTAL,
  };
}
JS

cat > src/domain/hissa/modes/metric.js <<'JS'
import { validateMetricRows } from "../validation/metric.js";
import { parseFlexibleInteger } from "../input/parser.js";

export const METRIC_TOTAL = 1000;

function round(value, digits = 8) {
  const factor = 10 ** digits;
  return Math.round((value + Number.EPSILON) * factor) / factor;
}

export function calculateMetric(payload) {
  const totalLand = Number(payload?.totalLand);

  if (!Number.isFinite(totalLand) || totalLand <= 0) {
    throw new Error(
      "মোট জমির পরিমাণ বসানো হয়নি। পরিমাণ বসিয়ে নিচের “হিসাব করুন” বাটনে আবার চাপুন।"
    );
  }

  const validated = validateMetricRows(payload?.rows);

  const rows = validated.rows.map((row) => {
    const ratio =
      row.share / validated.totalShare;

    return {
      ...row,
      ratio: round(ratio, 10),
      percentage: round(ratio * 100, 8),
      allocatedLand: round(totalLand * ratio, 8),
    };
  });

  return {
    mode: "metric",
    totalLand,
    totalShare: validated.totalShare,
    maxShare: METRIC_TOTAL,
    rows,
    explanation: [
      "Metric Mode-এ প্রতিটি শরিকের শেয়ার ১০০০-এর ভিত্তিতে হিসাব করা হয়।",
      `মোট তালিকাভুক্ত শেয়ার: ${validated.totalShare}।`,
      "প্রত্যেক শরিকের অংশ = শরিকের শেয়ার ÷ মোট তালিকাভুক্ত শেয়ার।",
      "বরাদ্দ জমি = মোট জমি × শরিকের অংশ।",
    ],
  };
}

export function parseMetricShare(value) {
  return parseFlexibleInteger(value, {
    allowBlank: false,
    min: 0,
    max: METRIC_TOTAL,
  });
}
JS

cat > tests/hissa/metric.test.js <<'JS'
import test from "node:test";
import assert from "node:assert/strict";

import {
  normalizeDigits,
  parseFlexibleInteger,
} from "../../src/domain/hissa/input/parser.js";

import {
  validateMetricRows,
} from "../../src/domain/hissa/validation/metric.js";

import {
  calculateMetric,
} from "../../src/domain/hissa/modes/metric.js";

test("metric accepts Bangla Unicode digits", () => {
  assert.equal(parseFlexibleInteger("৩০০"), 300);
  assert.equal(parseFlexibleInteger("৪০০"), 400);
});

test("metric accepts Arabic-Indic Unicode digits", () => {
  assert.equal(parseFlexibleInteger("٣٠٠"), 300);
});

test("metric normalizes mixed supported digits", () => {
  assert.equal(normalizeDigits("৩০০ + 400"), "300 + 400");
});

test("metric rejects total share above 1000", () => {
  assert.throws(
    () =>
      validateMetricRows([
        { name: "Karim", share: "600" },
        { name: "Rahim", share: "500" },
      ]),
    /১০০০-এর বেশি/
  );
});

test("metric rejects zero total share", () => {
  assert.throws(
    () =>
      validateMetricRows([
        { name: "Karim", share: "0" },
        { name: "Rahim", share: "0" },
      ]),
    /০ হতে পারে না/
  );
});

test("metric calculates 300/300/400 proportionally", () => {
  const result = calculateMetric({
    totalLand: 100,
    rows: [
      { name: "Karim", share: "300" },
      { name: "Rahim", share: "300" },
      { name: "Jalil", share: "400" },
    ],
  });

  assert.equal(result.totalShare, 1000);
  assert.equal(result.rows[0].percentage, 30);
  assert.equal(result.rows[1].percentage, 30);
  assert.equal(result.rows[2].percentage, 40);
  assert.equal(result.rows[0].allocatedLand, 30);
  assert.equal(result.rows[1].allocatedLand, 30);
  assert.equal(result.rows[2].allocatedLand, 40);
});

test("metric works with Bangla digits in calculation", () => {
  const result = calculateMetric({
    totalLand: 50,
    rows: [
      { name: "করিম", share: "৩০০" },
      { name: "রহিম", share: "৩০০" },
      { name: "জলিল", share: "৪০০" },
    ],
  });

  assert.equal(result.totalShare, 1000);
  assert.equal(result.rows[2].allocatedLand, 20);
});

test("metric allows a listed total below 1000 for proportional allocation", () => {
  const result = calculateMetric({
    totalLand: 100,
    rows: [
      { name: "Karim", share: "300" },
      { name: "Rahim", share: "200" },
    ],
  });

  assert.equal(result.totalShare, 500);
  assert.equal(result.rows[0].percentage, 60);
  assert.equal(result.rows[1].percentage, 40);
});
JS

echo
echo "Running Metric core tests..."
node --test tests/hissa/metric.test.js

echo
echo "Running existing Hissa tests..."
node --test tests/hissa/*.test.js

echo
echo "Running production build..."
npm run build

echo
echo "SUCCESS"
echo "Metric core created:"
echo "  src/domain/hissa/modes/metric.js"
echo "  src/domain/hissa/validation/metric.js"
echo "  src/domain/hissa/input/parser.js"
echo "  tests/hissa/metric.test.js"
echo
echo "Backup: $BACKUP_DIR"
echo
echo "NOTE: UI connection is intentionally NOT changed in this sprint."
