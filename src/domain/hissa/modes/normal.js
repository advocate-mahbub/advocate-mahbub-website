import { normalizeToTil } from "../units/normalize.js";
import { allocateLand } from "../allocation/land-allocation.js";
import {
  validateTotalLand,
  validateRows,
  getTotalShareTil,
  validateNormalTotalShare,
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
      name: row.name?.trim() || `শরীক ${String(index + 1).replace(/[0-9]/g, (digit) => "০১২৩৪৫৬৭৮৯"[digit])}`,
      shareTil: normalizeToTil(row),
    }))
    .filter((row) => row.shareTil > 0n);

  const rowCheck = validateRows(normalizedRows);

  if (!rowCheck.valid) {
    throw new RangeError(rowCheck.message);
  }

  const totalShareTil = getTotalShareTil(normalizedRows);
  const totalShareCheck = validateNormalTotalShare(totalShareTil);

  if (!totalShareCheck.valid) {
    throw new RangeError(totalShareCheck.message);
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
