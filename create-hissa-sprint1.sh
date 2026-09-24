#!/usr/bin/env bash

set -e

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$ROOT/backups/hissa-sprint1"

echo "=========================================="
echo "Hissa Calculator V1 - Sprint 1"
echo "Creating calculation domain..."
echo "=========================================="

# --------------------------------------------------
# 1. Backup existing Hissa files if any
# --------------------------------------------------

mkdir -p "$BACKUP_DIR"

for path in \
  "src/domain/hissa" \
  "src/data/hissa" \
  "tests/hissa"
do
  if [ -e "$ROOT/$path" ]; then
    echo "Backing up existing: $path"
    cp -R "$ROOT/$path" "$BACKUP_DIR/${path//\//-}-$STAMP"
  fi
done

# --------------------------------------------------
# 2. Create directory structure
# --------------------------------------------------

mkdir -p \
  src/domain/hissa/units \
  src/domain/hissa/modes \
  src/domain/hissa/allocation \
  src/domain/hissa/validation \
  src/domain/hissa/result \
  src/data/hissa \
  tests/hissa

# --------------------------------------------------
# 3. Unit constants
# --------------------------------------------------

cat > src/domain/hissa/units/constants.js <<'EOF'
export const HissaUnit = Object.freeze({
  ANNA_TO_TIL: 4800n,
  GONDA_TO_TIL: 240n,
  KORA_TO_TIL: 60n,
  KRANTI_TO_TIL: 20n,
  TIL_TO_TIL: 1n,

  FULL_HISSA_ANNA: 16,
  FULL_HISSA_TIL: 76800n,
});
EOF

# --------------------------------------------------
# 4. Normalize
# --------------------------------------------------

cat > src/domain/hissa/units/normalize.js <<'EOF'
import { HissaUnit } from "./constants.js";

function integer(value, field) {
  if (value === undefined || value === null || value === "") return 0n;

  if (!Number.isInteger(Number(value)) || Number(value) < 0) {
    throw new RangeError(`${field} must be a non-negative integer.`);
  }

  return BigInt(value);
}

export function normalizeToTil(input = {}) {
  const anna = integer(input.anna, "anna");
  const gonda = integer(input.gonda, "gonda");
  const kora = integer(input.kora, "kora");
  const kranti = integer(input.kranti, "kranti");
  const til = integer(input.til, "til");

  return (
    anna * HissaUnit.ANNA_TO_TIL +
    gonda * HissaUnit.GONDA_TO_TIL +
    kora * HissaUnit.KORA_TO_TIL +
    kranti * HissaUnit.KRANTI_TO_TIL +
    til
  );
}
EOF

# --------------------------------------------------
# 5. Denormalize
# --------------------------------------------------

cat > src/domain/hissa/units/denormalize.js <<'EOF'
import { HissaUnit } from "./constants.js";

export function denormalizeFromTil(value) {
  const til = BigInt(value);

  if (til < 0n) {
    throw new RangeError("Til value cannot be negative.");
  }

  const anna = til / HissaUnit.ANNA_TO_TIL;
  let remainder = til % HissaUnit.ANNA_TO_TIL;

  const gonda = remainder / HissaUnit.GONDA_TO_TIL;
  remainder %= HissaUnit.GONDA_TO_TIL;

  const kora = remainder / HissaUnit.KORA_TO_TIL;
  remainder %= HissaUnit.KORA_TO_TIL;

  const kranti = remainder / HissaUnit.KRANTI_TO_TIL;
  const finalTil = remainder % HissaUnit.KRANTI_TO_TIL;

  return {
    anna,
    gonda,
    kora,
    kranti,
    til: finalTil,
  };
}
EOF

# --------------------------------------------------
# 6. Input validation
# --------------------------------------------------

cat > src/domain/hissa/validation/input.js <<'EOF'
export function validateTotalLand(totalLand) {
  const value = Number(totalLand);

  if (!Number.isFinite(value) || value <= 0) {
    return {
      valid: false,
      message: "মোট জমির পরিমাণ ০-এর বেশি হতে হবে।",
    };
  }

  return { valid: true };
}

export function validateRows(rows = []) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return {
      valid: false,
      message: "কমপক্ষে একজন শরিক প্রয়োজন।",
    };
  }

  const hasPositiveShare = rows.some(
    (row) => BigInt(row.shareTil ?? 0) > 0n
  );

  if (!hasPositiveShare) {
    return {
      valid: false,
      message: "কমপক্ষে একজন শরিকের হিস্যা দিতে হবে।",
    };
  }

  return { valid: true };
}
EOF

# --------------------------------------------------
# 7. Notation validation
# --------------------------------------------------

cat > src/domain/hissa/validation/notation.js <<'EOF'
export const NOTATION_LIMITS = Object.freeze({
  anna: { min: 0, max: 15 },
  gonda: { min: 0, max: 19 },
  kora: { min: 0, max: 3 },
  kranti: { min: 0, max: 19 },
  til: { min: 0, max: 19 },
});

export function validateNotation(input = {}) {
  for (const [field, limits] of Object.entries(NOTATION_LIMITS)) {
    const value = Number(input[field] ?? 0);

    if (
      !Number.isInteger(value) ||
      value < limits.min ||
      value > limits.max
    ) {
      return {
        valid: false,
        field,
        message: `${field} এর মান ${limits.min} থেকে ${limits.max} এর মধ্যে হতে হবে।`,
      };
    }
  }

  return { valid: true };
}
EOF

# --------------------------------------------------
# 8. Land allocation
# --------------------------------------------------

cat > src/domain/hissa/allocation/land-allocation.js <<'EOF'
export function allocateLand(totalLand, rows) {
  const land = Number(totalLand);

  if (!Number.isFinite(land) || land <= 0) {
    throw new RangeError("Total land must be greater than zero.");
  }

  const totalShareTil = rows.reduce(
    (sum, row) => sum + BigInt(row.shareTil),
    0n
  );

  if (totalShareTil <= 0n) {
    throw new RangeError(
      "Total listed share must be greater than zero."
    );
  }

  return rows.map((row) => {
    const shareTil = BigInt(row.shareTil);

    const allocationRatio =
      Number(shareTil) / Number(totalShareTil);

    const allocatedLand =
      land * allocationRatio;

    const absoluteRatio =
      Number(shareTil) / 76800;

    return {
      ...row,
      shareTil,
      allocationRatio,
      absoluteRatio,
      allocatedLand,
    };
  });
}
EOF

# --------------------------------------------------
# 9. Normal Mode
# --------------------------------------------------

cat > src/domain/hissa/modes/normal.js <<'EOF'
import { normalizeToTil } from "../units/normalize.js";
import { allocateLand } from "../allocation/land-allocation.js";
import {
  validateTotalLand,
  validateRows,
} from "../validation/input.js";

export function calculateNormal({
  totalLand,
  rows = [],
}) {
  const landCheck = validateTotalLand(totalLand);

  if (!landCheck.valid) {
    throw new RangeError(landCheck.message);
  }

  const normalizedRows = rows
    .map((row, index) => ({
      id: row.id ?? `normal-${index + 1}`,
      name: row.name?.trim() || `শরিক ${index + 1}`,
      shareTil: normalizeToTil(row),
    }))
    .filter((row) => row.shareTil > 0n);

  const rowCheck = validateRows(normalizedRows);

  if (!rowCheck.valid) {
    throw new RangeError(rowCheck.message);
  }

  const allocated = allocateLand(
    totalLand,
    normalizedRows
  );

  return {
    mode: "normal",
    totalLand: Number(totalLand),
    totalListedShareTil: allocated.reduce(
      (sum, row) => sum + row.shareTil,
      0n
    ),
    rows: allocated,
  };
}
EOF

# --------------------------------------------------
# 10. GroupLine Mode
# --------------------------------------------------

cat > src/domain/hissa/modes/groupline.js <<'EOF'
import { normalizeToTil } from "../units/normalize.js";
import { allocateLand } from "../allocation/land-allocation.js";
import {
  validateTotalLand,
  validateRows,
} from "../validation/input.js";

export function calculateGroupLine({
  totalLand,
  rows = [],
}) {
  const landCheck = validateTotalLand(totalLand);

  if (!landCheck.valid) {
    throw new RangeError(landCheck.message);
  }

  const normalizedRows = rows
    .map((row, index) => ({
      id: row.id ?? `groupline-${index + 1}`,
      name: row.name?.trim() || `Group ${index + 1}`,
      shareTil: normalizeToTil(row),
    }))
    .filter((row) => row.shareTil > 0n);

  const rowCheck = validateRows(normalizedRows);

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
  };
}
EOF

# --------------------------------------------------
# 11. Result formatter
# --------------------------------------------------

cat > src/domain/hissa/result/formatter.js <<'EOF'
export function formatLand(
  value,
  maximumFractionDigits = 6
) {
  return Number(value).toLocaleString("en-US", {
    minimumFractionDigits: 0,
    maximumFractionDigits,
  });
}

export function formatPercent(value) {
  return `${(Number(value) * 100).toFixed(4)}%`;
}
EOF

# --------------------------------------------------
# 12. Calculation explanation
# --------------------------------------------------

cat > src/domain/hissa/result/explanation.js <<'EOF'
export function buildExplanation(result) {
  return {
    mode: result.mode,

    steps: [
      "প্রতিটি শরিকের হিস্যা internal Til unit-এ normalize করা হয়েছে।",
      "তালিকাভুক্ত সব শরিকের normalized হিস্যা যোগ করে Total Listed Share নির্ধারণ করা হয়েছে।",
      "প্রতিটি শরিকের Allocation Ratio = Individual Share ÷ Total Listed Share।",
      "Allocated Land = Total Land × Allocation Ratio।",
    ],
  };
}
EOF

# --------------------------------------------------
# 13. Domain index
# --------------------------------------------------

cat > src/domain/hissa/index.js <<'EOF'
export { HissaUnit } from "./units/constants.js";

export { normalizeToTil } from "./units/normalize.js";
export { denormalizeFromTil } from "./units/denormalize.js";

export { calculateNormal } from "./modes/normal.js";
export { calculateGroupLine } from "./modes/groupline.js";

export { allocateLand } from "./allocation/land-allocation.js";

export { validateNotation } from "./validation/notation.js";

export { buildExplanation } from "./result/explanation.js";

export {
  formatLand,
  formatPercent,
} from "./result/formatter.js";
EOF

# --------------------------------------------------
# 14. Golden cases
# --------------------------------------------------

cat > src/data/hissa/golden-cases.js <<'EOF'
// Reference cases derived from 1-16.xlsx.
// Names are intentionally excluded from production UI data.

export const goldenCases = Object.freeze({
  normal126: {
    totalLand: 158,

    rows: [
      {
        anna: 5,
        gonda: 6,
        kora: 2,
        kranti: 2,
        til: 0,
      },
      {
        anna: 5,
        gonda: 6,
        kora: 2,
        kranti: 2,
        til: 0,
      },
      {
        anna: 1,
        gonda: 17,
        kora: 1,
        kranti: 1,
        til: 0,
      },
      {
        anna: 1,
        gonda: 17,
        kora: 1,
        kranti: 1,
        til: 0,
      },
      {
        anna: 0,
        gonda: 18,
        kora: 2,
        kranti: 2,
        til: 0,
      },
      {
        anna: 0,
        gonda: 13,
        kora: 1,
        kranti: 1,
        til: 0,
      },
    ],
  },

  normalKaram: {
    totalLand: 31.5,

    rows: [
      {
        anna: 6,
        gonda: 7,
        kora: 1,
        kranti: 0,
        til: 0,
      },
      {
        anna: 6,
        gonda: 7,
        kora: 1,
        kranti: 0,
        til: 0,
      },
      {
        anna: 2,
        gonda: 0,
        kora: 0,
        kranti: 0,
        til: 0,
      },
    ],
  },

  normalBaten: {
    totalLand: 31.5,

    rows: [
      {
        anna: 2,
        gonda: 2,
        kora: 2,
        kranti: 0,
        til: 0,
      },
      {
        anna: 0,
        gonda: 18,
        kora: 2,
        kranti: 0,
        til: 0,
      },
      {
        anna: 0,
        gonda: 14,
        kora: 2,
        kranti: 0,
        til: 0,
      },
    ],
  },

  groupLine: {
    totalLand: 1,

    rows: [
      {
        anna: 0,
        gonda: 8,
        kora: 1,
        kranti: 0,
        til: 0,
      },
      {
        anna: 0,
        gonda: 4,
        kora: 0,
        kranti: 1,
        til: 10,
      },
      {
        anna: 0,
        gonda: 4,
        kora: 0,
        kranti: 1,
        til: 10,
      },
      {
        anna: 0,
        gonda: 8,
        kora: 3,
        kranti: 0,
        til: 0,
      },
      {
        anna: 0,
        gonda: 16,
        kora: 0,
        kranti: 0,
        til: 0,
      },
      {
        anna: 0,
        gonda: 16,
        kora: 0,
        kranti: 0,
        til: 0,
      },
    ],
  },
});
EOF

# --------------------------------------------------
# 15. Unit tests
# --------------------------------------------------

cat > tests/hissa/units.test.js <<'EOF'
import test from "node:test";
import assert from "node:assert/strict";

import { normalizeToTil } from "../../src/domain/hissa/units/normalize.js";
import { denormalizeFromTil } from "../../src/domain/hissa/units/denormalize.js";

test("unit normalization uses Til as exact internal base", () => {
  assert.equal(
    normalizeToTil({ anna: 1 }),
    4800n
  );

  assert.equal(
    normalizeToTil({ gonda: 1 }),
    240n
  );

  assert.equal(
    normalizeToTil({ kora: 1 }),
    60n
  );

  assert.equal(
    normalizeToTil({ kranti: 1 }),
    20n
  );

  assert.equal(
    normalizeToTil({ til: 1 }),
    1n
  );
});

test("normalization round-trips compound notation", () => {
  const value = normalizeToTil({
    anna: 5,
    gonda: 6,
    kora: 2,
    kranti: 2,
  });

  assert.deepEqual(
    denormalizeFromTil(value),
    {
      anna: 5n,
      gonda: 6n,
      kora: 2n,
      kranti: 2n,
      til: 0n,
    }
  );
});
EOF

# --------------------------------------------------
# 16. Normal tests
# --------------------------------------------------

cat > tests/hissa/normal.test.js <<'EOF'
import test from "node:test";
import assert from "node:assert/strict";

import { calculateNormal } from "../../src/domain/hissa/modes/normal.js";
import { goldenCases } from "../../src/data/hissa/golden-cases.js";

test("normal 126 case preserves proportional allocation", () => {
  const result = calculateNormal(
    goldenCases.normal126
  );

  assert.equal(
    result.totalListedShareTil,
    76800n
  );

  assert.ok(
    Math.abs(
      result.rows[0].allocatedLand -
      52.6666666667
    ) < 1e-9
  );

  assert.ok(
    Math.abs(
      result.rows[2].allocatedLand -
      18.4333333333
    ) < 1e-9
  );
});

test("normal Karam case allocates against listed share total", () => {
  const result = calculateNormal(
    goldenCases.normalKaram
  );

  assert.equal(
    result.totalListedShareTil,
    70680n
  );

  assert.ok(
    Math.abs(
      result.rows[0].allocatedLand -
      13.6108
    ) < 0.001
  );
});

test("normal Baten case allocates against listed share total", () => {
  const result = calculateNormal(
    goldenCases.normalBaten
  );

  assert.equal(
    result.totalListedShareTil,
    18120n
  );

  assert.ok(
    Math.abs(
      result.rows[0].allocatedLand -
      17.7318
    ) < 0.001
  );
});
EOF

# --------------------------------------------------
# 17. GroupLine tests
# --------------------------------------------------

cat > tests/hissa/groupline.test.js <<'EOF'
import test from "node:test";
import assert from "node:assert/strict";

import { calculateGroupLine } from "../../src/domain/hissa/modes/groupline.js";
import { goldenCases } from "../../src/data/hissa/golden-cases.js";

test("group line normalizes and allocates proportionally", () => {
  const result = calculateGroupLine(
    goldenCases.groupLine
  );

  assert.equal(
    result.totalListedShareTil,
    13740n
  );

  assert.ok(
    Math.abs(
      result.rows[0].allocationRatio -
      99 / 687
    ) < 1e-12
  );

  assert.ok(
    Math.abs(
      result.rows[1].allocationRatio -
      49.5 / 687
    ) < 1e-12
  );
});
EOF

# --------------------------------------------------
# 18. Allocation tests
# --------------------------------------------------

cat > tests/hissa/allocation.test.js <<'EOF'
import test from "node:test";
import assert from "node:assert/strict";

import { allocateLand } from "../../src/domain/hissa/allocation/land-allocation.js";

test("allocation ratios sum to one", () => {
  const result = allocateLand(100, [
    { shareTil: 100n },
    { shareTil: 300n },
  ]);

  const sum = result.reduce(
    (total, row) =>
      total + row.allocationRatio,
    0
  );

  assert.ok(
    Math.abs(sum - 1) < 1e-12
  );

  assert.equal(
    result[0].allocatedLand,
    25
  );

  assert.equal(
    result[1].allocatedLand,
    75
  );
});
EOF

# --------------------------------------------------
# 19. Edge-case tests
# --------------------------------------------------

cat > tests/hissa/edge-cases.test.js <<'EOF'
import test from "node:test";
import assert from "node:assert/strict";

import { calculateNormal } from "../../src/domain/hissa/modes/normal.js";

test("blank name gets a temporary label", () => {
  const result = calculateNormal({
    totalLand: 10,

    rows: [
      {
        name: "",
        anna: 1,
        gonda: 0,
        kora: 0,
        kranti: 0,
        til: 0,
      },
    ],
  });

  assert.equal(
    result.rows[0].name,
    "শরিক ১"
  );
});

test("zero-share rows do not affect allocation", () => {
  const result = calculateNormal({
    totalLand: 10,

    rows: [
      { anna: 1 },

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

test("invalid total land is rejected", () => {
  assert.throws(
    () =>
      calculateNormal({
        totalLand: 0,
        rows: [{ anna: 1 }],
      }),
    /মোট জমির পরিমাণ/
  );
});
EOF

echo ""
echo "=========================================="
echo "Hissa Calculator Sprint 1 created."
echo "=========================================="
echo ""

echo "Files created:"
find \
  src/domain/hissa \
  src/data/hissa \
  tests/hissa \
  -type f \
  | sort

echo ""
echo "Next step:"
echo "node --test tests/hissa/*.test.js"
echo ""
