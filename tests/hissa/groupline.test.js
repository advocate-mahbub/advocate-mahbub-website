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
