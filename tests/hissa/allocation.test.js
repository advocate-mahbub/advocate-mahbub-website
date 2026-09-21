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
