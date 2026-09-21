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
