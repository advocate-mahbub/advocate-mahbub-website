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
