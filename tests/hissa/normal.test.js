import test from "node:test";
import assert from "node:assert/strict";

import { calculateNormal } from "../../src/domain/hissa/modes/normal.js";
import { calculateGroupLine } from "../../src/domain/hissa/modes/groupline.js";
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
  const result = calculateGroupLine(
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
  const result = calculateGroupLine(
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

test("normal requires exactly 16 Anna", () => {
  const belowFull = {
    totalLand: 100,
    rows: [
      {
        name: "Karim",
        anna: 15,
        gonda: 19,
        kora: 3,
        kranti: 2,
        til: 18,
      },
    ],
  };

  assert.throws(
    () => calculateNormal(belowFull),
    /১৬ আনার কম/
  );

  const exactFull = {
    totalLand: 100,
    rows: [
      {
        name: "Karim",
        anna: 15,
        gonda: 19,
        kora: 3,
        kranti: 2,
        til: 19,
      },
    ],
  };

  const result = calculateNormal(exactFull);

  assert.equal(result.totalListedShareTil, 76800n);
});

test("normal rejects more than 16 Anna", () => {
  assert.throws(
    () =>
      calculateNormal({
        totalLand: 100,
        rows: [
          {
            name: "Karim",
            anna: 15,
            gonda: 19,
            kora: 3,
            kranti: 3,
            til: 0,
          },
        ],
      }),
    /১৬ আনার বেশি/
  );
});

