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
