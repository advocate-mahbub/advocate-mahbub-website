import { normalizeToTil } from "../units/normalize.js";
import { allocateLand } from "../allocation/land-allocation.js";
import {
  validateTotalLand,
  validateRows,
  getTotalShareTil,
  getGroupLineTotalShareNote,
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
      name: row.name?.trim() || `Group ${String(index + 1).replace(/[0-9]/g, (digit) => "০১২৩৪৫৬৭৮৯"[digit])}`,
      shareTil: normalizeToTil(row),
    }))
    .filter((row) => row.shareTil > 0n);

  const rowCheck = validateRows(normalizedRows);

  if (!rowCheck.valid) {
    throw new RangeError(rowCheck.message);
  }

  const totalShareTil = getTotalShareTil(normalizedRows);
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
  };
}
