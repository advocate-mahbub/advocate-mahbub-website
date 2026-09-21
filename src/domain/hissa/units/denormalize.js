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
