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
