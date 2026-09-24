import test from "node:test";
import assert from "node:assert/strict";

import {
  normalizeDigits,
  parseFlexibleInteger,
} from "../../src/domain/hissa/input/parser.js";

import {
  validateMetricRows,
} from "../../src/domain/hissa/validation/metric.js";

import {
  calculateMetric,
} from "../../src/domain/hissa/modes/metric.js";

test("metric accepts Bangla Unicode digits", () => {
  assert.equal(parseFlexibleInteger("৩০০"), 300);
  assert.equal(parseFlexibleInteger("৪০০"), 400);
});

test("metric accepts Arabic-Indic Unicode digits", () => {
  assert.equal(parseFlexibleInteger("٣٠٠"), 300);
});

test("metric normalizes mixed supported digits", () => {
  assert.equal(normalizeDigits("৩০০ + 400"), "300 + 400");
});

test("metric allows total share above 1000", () => {
  const result = calculateMetric({
    totalLand: 100,
    rows: [
      { name: "Karim", share: "600" },
      { name: "Rahim", share: "500" },
    ],
  });

  assert.equal(result.totalShare, 1100);
  assert.equal(result.rows[0].percentage, 600 / 11);
  assert.equal(result.rows[1].percentage, 500 / 11);
});

test("metric rejects zero total share", () => {
  assert.throws(
    () =>
      validateMetricRows([
        { name: "Karim", share: "0" },
        { name: "Rahim", share: "0" },
      ]),
    /০ হতে পারে না/
  );
});

test("metric calculates 300/300/400 proportionally", () => {
  const result = calculateMetric({
    totalLand: 100,
    rows: [
      { name: "Karim", share: "300" },
      { name: "Rahim", share: "300" },
      { name: "Jalil", share: "400" },
    ],
  });

  assert.equal(result.totalShare, 1000);
  assert.equal(result.rows[0].percentage, 30);
  assert.equal(result.rows[1].percentage, 30);
  assert.equal(result.rows[2].percentage, 40);
  assert.equal(result.rows[0].allocatedLand, 30);
  assert.equal(result.rows[1].allocatedLand, 30);
  assert.equal(result.rows[2].allocatedLand, 40);
});

test("metric works with Bangla digits in calculation", () => {
  const result = calculateMetric({
    totalLand: 50,
    rows: [
      { name: "করিম", share: "৩০০" },
      { name: "রহিম", share: "৩০০" },
      { name: "জলিল", share: "৪০০" },
    ],
  });

  assert.equal(result.totalShare, 1000);
  assert.equal(result.rows[2].allocatedLand, 20);
});

test("metric allows a listed total below 1000 for proportional allocation", () => {
  const result = calculateMetric({
    totalLand: 100,
    rows: [
      { name: "Karim", share: "300" },
      { name: "Rahim", share: "200" },
    ],
  });

  assert.equal(result.totalShare, 500);
  assert.equal(result.rows[0].percentage, 60);
  assert.equal(result.rows[1].percentage, 40);
});
