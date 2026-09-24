#!/usr/bin/env bash
set -euo pipefail

echo "=== Hissa Correction: Normal / GroupLine / Metric ==="

STAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKUP_DIR="backups/hissa-correction-${STAMP}"

mkdir -p "$BACKUP_DIR"

echo
echo "1. Creating Hissa backup..."

cp src/domain/hissa/validation/input.js "$BACKUP_DIR/"
cp src/domain/hissa/modes/normal.js "$BACKUP_DIR/"
cp src/domain/hissa/modes/groupline.js "$BACKUP_DIR/"
cp src/domain/hissa/modes/metric.js "$BACKUP_DIR/"
cp src/domain/hissa/validation/metric.js "$BACKUP_DIR/"
cp src/scripts/hissa-calculator.js "$BACKUP_DIR/"
cp src/scripts/hissa-metric-ui.js "$BACKUP_DIR/"
cp tests/hissa/normal.test.js "$BACKUP_DIR/"
cp tests/hissa/edge-cases.test.js "$BACKUP_DIR/"
cp tests/hissa/metric.test.js "$BACKUP_DIR/"

echo "Backup: $BACKUP_DIR"

python - <<'PY'
from pathlib import Path

# ============================================================
# 1. INPUT VALIDATION
# ============================================================

path = Path("src/domain/hissa/validation/input.js")
text = path.read_text(encoding="utf-8")

# Remove previous helper block if it exists.
marker = "\nexport const FULL_NORMAL_SHARE_TIL = 76800n;"

if marker in text:
    text = text.split(marker)[0].rstrip() + "\n"

text += r'''

export const FULL_NORMAL_SHARE_TIL = 76800n;
export const NORMAL_MIN_SHAREHOLDERS = 2;

export function getTotalShareTil(rows = []) {
  return rows.reduce(
    (sum, row) => sum + BigInt(row.shareTil ?? 0),
    0n
  );
}

export function validateNormalShareholders(rows = []) {
  if (!Array.isArray(rows) || rows.length < NORMAL_MIN_SHAREHOLDERS) {
    return {
      valid: false,
      message:
        "Normal Mode-এ কমপক্ষে ২ জন শরিক প্রয়োজন। একজন শরিকের হিসাবের জন্য GroupLine Mode ব্যবহার করুন।",
    };
  }

  return { valid: true };
}

export function validateNormalTotalShare(totalShareTil) {
  const total = BigInt(totalShareTil ?? 0);

  if (total < FULL_NORMAL_SHARE_TIL) {
    return {
      valid: false,
      message:
        "জমি ১৬ আনার কম! ভালো করে যাচাই করুন। খতিয়ানে ভুল আছে কি না, ভালো করে দেখুন!",
    };
  }

  if (total > FULL_NORMAL_SHARE_TIL) {
    return {
      valid: false,
      message:
        "জমি ১৬ আনার বেশি! ভালো করে যাচাই করুন। খতিয়ানে ভুল আছে কি না, ভালো করে দেখুন!",
    };
  }

  return { valid: true };
}

export function getGroupLineTotalShareNote(totalShareTil) {
  const total = BigInt(totalShareTil ?? 0);

  if (total < FULL_NORMAL_SHARE_TIL) {
    return "নোট: প্রদত্ত শরিকদের মোট হিস্যা ১৬ আনার কম। হিসাব দেওয়া হয়েছে, তবে খতিয়ানের সম্পূর্ণ হিস্যা দেওয়া হয়েছে কি না যাচাই করুন।";
  }

  if (total > FULL_NORMAL_SHARE_TIL) {
    return "নোট: প্রদত্ত শরিকদের মোট হিস্যা ১৬ আনার বেশি। হিসাব দেওয়া হয়েছে, তবে ইনপুটের হিস্যা ও খতিয়ানের তথ্য ভালোভাবে যাচাই করুন।";
  }

  return "";
}
'''

path.write_text(text, encoding="utf-8")


# ============================================================
# 2. NORMAL MODE
# ============================================================

path = Path("src/domain/hissa/modes/normal.js")
text = path.read_text(encoding="utf-8")

text = text.replace(
'''  validateTotalLand,
  validateRows,
} from "../validation/input.js";''',
'''  validateTotalLand,
  validateRows,
  getTotalShareTil,
  validateNormalShareholders,
  validateNormalTotalShare,
} from "../validation/input.js";'''
)

old = '''  const rowCheck = validateRows(normalizedRows);

  if (!rowCheck.valid) {
    throw new RangeError(rowCheck.message);
  }

  const allocated = allocateLand(
    totalLand,
    normalizedRows
  );'''

new = '''  const rowCheck = validateRows(normalizedRows);

  if (!rowCheck.valid) {
    throw new RangeError(rowCheck.message);
  }

  const shareholderCheck =
    validateNormalShareholders(normalizedRows);

  if (!shareholderCheck.valid) {
    throw new RangeError(shareholderCheck.message);
  }

  const totalShareTil =
    getTotalShareTil(normalizedRows);

  const totalShareCheck =
    validateNormalTotalShare(totalShareTil);

  if (!totalShareCheck.valid) {
    throw new RangeError(totalShareCheck.message);
  }

  const allocated = allocateLand(
    totalLand,
    normalizedRows
  );'''

if old not in text:
    raise SystemExit(
        "ERROR: Normal Mode validation insertion point not found."
    )

text = text.replace(old, new)

text = text.replace(
'''    totalListedShareTil: allocated.reduce(
      (sum, row) => sum + row.shareTil,
      0n
    ),''',
'''    totalListedShareTil: totalShareTil,''',
)

path.write_text(text, encoding="utf-8")


# ============================================================
# 3. GROUPLINE MODE
# ============================================================

path = Path("src/domain/hissa/modes/groupline.js")
text = path.read_text(encoding="utf-8")

text = text.replace(
'''  validateTotalLand,
  validateRows,
} from "../validation/input.js";''',
'''  validateTotalLand,
  validateRows,
  getTotalShareTil,
  getGroupLineTotalShareNote,
} from "../validation/input.js";'''
)

old = '''  const rowCheck = validateRows(normalizedRows);

  if (!rowCheck.valid) {
    throw new RangeError(rowCheck.message);
  }

  const allocated = allocateLand(
    totalLand,
    normalizedRows
  );

  return {
    mode: "groupline",
    totalLand: Number(totalLand),
    totalListedShareTil: allocated.reduce(
      (sum, row) => sum + row.shareTil,
      0n
    ),
    rows: allocated,
  };'''

new = '''  const rowCheck = validateRows(normalizedRows);

  if (!rowCheck.valid) {
    throw new RangeError(rowCheck.message);
  }

  const totalShareTil =
    getTotalShareTil(normalizedRows);

  const totalShareNote =
    getGroupLineTotalShareNote(totalShareTil);

  const allocated = allocateLand(
    totalLand,
    normalizedRows
  );

  return {
    mode: "groupline",
    totalLand: Number(totalLand),
    totalListedShareTil: totalShareTil,
    totalShareNote,
    rows: allocated,
  };'''

if old not in text:
    raise SystemExit(
        "ERROR: GroupLine validation/result block not found."
    )

text = text.replace(old, new)

path.write_text(text, encoding="utf-8")


# ============================================================
# 4. METRIC DOMAIN
# ============================================================

path = Path("src/domain/hissa/validation/metric.js")
text = path.read_text(encoding="utf-8")

old = '''  if (totalShare > METRIC_TOTAL) {
    throw new Error(
      "মোট হিস্যা ১০০০-এর বেশি হয়েছে। ইনপুটে কোথাও ভুল থাকতে পারে। খতিয়ান বা মূল নথির তথ্য আবার যাচাই করুন।"
    );
  }

'''

if old not in text:
    raise SystemExit(
        "ERROR: Metric >1000 rejection block not found."
    )

text = text.replace(old, "")

path.write_text(text, encoding="utf-8")


# ============================================================
# 5. METRIC TESTS
# ============================================================

path = Path("tests/hissa/metric.test.js")
text = path.read_text(encoding="utf-8")

old = '''test("metric rejects total share above 1000", () => {
  assert.throws(
    () =>
      validateMetricRows([
        { name: "Karim", share: "600" },
        { name: "Rahim", share: "500" },
      ]),
    /১০০০-এর বেশি/
  );
});
'''

new = '''test("metric allows total share above 1000", () => {
  const result = calculateMetric({
    totalLand: 100,
    rows: [
      { name: "Karim", share: "600" },
      { name: "Rahim", share: "500" },
    ],
  });

  assert.equal(result.totalShare, 1100);
  assert.equal(result.rows[0].allocatedLand, 600 / 11);
  assert.equal(result.rows[1].allocatedLand, 500 / 11);
});
'''

if old not in text:
    raise SystemExit(
        "ERROR: Metric >1000 test block not found."
    )

text = text.replace(old, new)

# validateMetricRows import is still useful for zero-total test.
path.write_text(text, encoding="utf-8")


# ============================================================
# 6. NORMAL TESTS
# ============================================================

path = Path("tests/hissa/normal.test.js")
text = path.read_text(encoding="utf-8")

# Karam and Baten remain historical calculation references,
# but they are not Normal production-mode validation cases.
text = text.replace(
'''import { calculateNormal } from "../../src/domain/hissa/modes/normal.js";
import { goldenCases } from "../../src/data/hissa/golden-cases.js";''',
'''import { calculateNormal } from "../../src/domain/hissa/modes/normal.js";
import { calculateGroupLine } from "../../src/domain/hissa/modes/groupline.js";
import { goldenCases } from "../../src/data/hissa/golden-cases.js";'''
)

text = text.replace(
'''  const result = calculateNormal(
    goldenCases.normalKaram
  );''',
'''  const result = calculateGroupLine(
    goldenCases.normalKaram
  );'''
)

text = text.replace(
'''  const result = calculateNormal(
    goldenCases.normalBaten
  );''',
'''  const result = calculateGroupLine(
    goldenCases.normalBaten
  );'''
)

# Remove any previous experimental Normal boundary tests.
lines = text.splitlines()
cleaned = []
skip = False
depth = 0

for line in lines:
    if (
        line.startswith('test("normal requires exactly 16 Anna"')
        or line.startswith('test("normal rejects more than 16 Anna"')
    ):
        skip = True
        depth = line.count("{") - line.count("}")
        continue

    if skip:
        depth += line.count("{") - line.count("}")
        if depth <= 0 and line.strip() == "}"):
            skip = False
        continue

    cleaned.append(line)

text = "\n".join(cleaned).rstrip() + "\n"

text += r'''

test("normal rejects fewer than two shareholders", () => {
  assert.throws(
    () =>
      calculateNormal({
        totalLand: 100,
        rows: [
          {
            name: "Karim",
            anna: 8,
          },
        ],
      }),
    /কমপক্ষে ২ জন শরিক/
  );
});

test("normal accepts two or more shareholders when total is exactly 16 Anna", () => {
  const result = calculateNormal(
    goldenCases.normal126
  );

  assert.ok(result.rows.length >= 2);
  assert.equal(result.totalListedShareTil, 76800n);
});

test("normal rejects total below 16 Anna", () => {
  assert.throws(
    () =>
      calculateNormal({
        totalLand: 100,
        rows: [
          { name: "Karim", anna: 8 },
          { name: "Rahim", anna: 7 },
        ],
      }),
    /১৬ আনার কম/
  );
});

test("normal rejects total above 16 Anna", () => {
  assert.throws(
    () =>
      calculateNormal({
        totalLand: 100,
        rows: [
          { name: "Karim", anna: 9 },
          { name: "Rahim", anna: 8 },
        ],
      }),
    /১৬ আনার বেশি/
  );
});
'''

path.write_text(text, encoding="utf-8")


# ============================================================
# 7. EDGE CASE TESTS
# ============================================================

path = Path("tests/hissa/edge-cases.test.js")
text = path.read_text(encoding="utf-8")

old = '''test("blank name gets a temporary label with a full 16 Anna share", () => {
  const result = calculateNormal({
    totalLand: 10,

    rows: [
      {
        name: "",
        anna: 15,
        gonda: 19,
        kora: 3,
        kranti: 2,
        til: 19,
      },
    ],
  });

  assert.equal(
    result.rows[0].name,
    "শরিক ১"
  );
});
'''

new = '''test("blank name gets a temporary label in a valid Normal calculation", () => {
  const result = calculateNormal({
    totalLand: 10,

    rows: [
      {
        name: "",
        anna: 8,
      },
      {
        name: "Rahim",
        anna: 8,
      },
    ],
  });

  assert.equal(
    result.rows[0].name,
    "শরিক ১"
  );
});
'''

if old not in text:
    raise SystemExit(
        "ERROR: blank-name edge test block not found."
    )

text = text.replace(old, new)

old = '''test("zero-share rows do not affect allocation", () => {
  const result = calculateNormal({
    totalLand: 10,

    rows: [
      {
        anna: 15,
        gonda: 19,
        kora: 3,
        kranti: 2,
        til: 19,
      },

      {
        anna: 0,
        gonda: 0,
        kora: 0,
        kranti: 0,
        til: 0,
      },
    ],
  });

  assert.equal(
    result.rows.length,
    1
  );

  assert.equal(
    result.rows[0].allocatedLand,
    10
  );
});
'''

new = '''test("zero-share rows do not affect allocation", () => {
  const result = calculateNormal({
    totalLand: 10,

    rows: [
      { anna: 8 },
      { anna: 8 },
      {
        anna: 0,
        gonda: 0,
        kora: 0,
        kranti: 0,
        til: 0,
      },
    ],
  });

  assert.equal(
    result.rows.length,
    2
  );

  assert.equal(
    result.rows[0].allocatedLand,
    5
  );
});
'''

if old not in text:
    raise SystemExit(
        "ERROR: zero-share edge test block not found."
    )

text = text.replace(old, new)

path.write_text(text, encoding="utf-8")


# ============================================================
# 8. RESULT NOTE IN MAIN UI
# ============================================================

path = Path("src/scripts/hissa-calculator.js")
text = path.read_text(encoding="utf-8")

old = '''  elements.resultRows.innerHTML = result.rows
    .map((row, index) => {'''

new = '''  const noteHtml = result.totalShareNote
    ? `<div class="hissa-mode-note" role="note">${escapeHtml(result.totalShareNote)}</div>`
    : "";

  elements.resultRows.innerHTML =
    noteHtml +
    result.rows
    .map((row, index) => {'''

if old in text and "const noteHtml = result.totalShareNote" not in text:
    text = text.replace(old, new)

path.write_text(text, encoding="utf-8")


# ============================================================
# 9. METRIC UI
# ============================================================

path = Path("src/scripts/hissa-metric-ui.js")
text = path.read_text(encoding="utf-8")

old = '''  if (total > 1000) {
    showMetricError(
      `মোট হিস্যা ${banglaNumber(total)}। Metric Mode-এ মোট হিস্যা ১০০০-এর বেশি হতে পারে না। ` +
      `কোথাও ইনপুটে ভুল হয়েছে কি না, অথবা মূল খতিয়ানের হিস্যায় ভুল আছে কি না, অনুগ্রহ করে যাচাই করুন।`
    );
    return;
  }

'''

if old in text:
    text = text.replace(old, "")

if "const totalNote =" not in text:
    anchor = '''  if (total === 0) {
    showMetricError("অন্তত একজন শরিকের হিস্যা দিতে হবে।");
    return;
  }
'''

    if anchor not in text:
        raise SystemExit(
            "ERROR: Metric zero-total validation anchor not found."
        )

    replacement = anchor + '''
  const totalNote =
    total < 1000
      ? "নোট: প্রদত্ত মোট হিস্যা ১০০০-এর কম। হিসাব দেওয়া হয়েছে, তবে খতিয়ানের সম্পূর্ণ অংশ দেওয়া হয়েছে কি না যাচাই করুন।"
      : total > 1000
        ? "নোট: প্রদত্ত মোট হিস্যা ১০০০-এর বেশি। হিসাব দেওয়া হয়েছে, তবে ইনপুটের অংশ ও খতিয়ানের তথ্য ভালোভাবে যাচাই করুন।"
        : "";
'''

    text = text.replace(anchor, replacement)

if "const noteHtml = totalNote" not in text:
    anchor = '''  if (!e.resultRows) return;

  e.resultRows.innerHTML = rows.map(row => {'''

    if anchor not in text:
        raise SystemExit(
            "ERROR: Metric result insertion point not found."
        )

    replacement = '''  if (!e.resultRows) return;

  const noteHtml = totalNote
    ? `<div class="hissa-mode-note" role="note">${escapeHtml(totalNote)}</div>`
    : "";

  e.resultRows.innerHTML =
    noteHtml +
    rows.map(row => {'''

    text = text.replace(anchor, replacement)

path.write_text(text, encoding="utf-8")


print()
print("Hissa correction patch completed.")
print(f"Backup: {BACKUP_DIR}")
