// ============================================================
// Isolated Metric Mode calculation engine
// ============================================================
// This file is deliberately independent from:
// - Normal Mode
// - GroupLine Mode
// - Astro
// - DOM
// - localStorage
// ============================================================

import { parseMetricNumber } from './parser.js';
import {
  METRIC_TOTAL_SHARE,
  validateMetricTotalShare,
  validateMetricRows,
} from './validation.js';

export function calculateMetric({
  totalLand,
  totalShare = METRIC_TOTAL_SHARE,
  rows = [],
}) {
  const land = parseMetricNumber(totalLand);
  const metricTotal = parseMetricNumber(totalShare);

  if (land === null || land <= 0) {
    throw new Error('মোট জমির পরিমাণ ০-এর বেশি হতে হবে।');
  }

  if (metricTotal === null) {
    throw new Error('মোট হিস্যার পরিমাণ সঠিক নয়।');
  }

  const totalValidation = validateMetricTotalShare(metricTotal);
  if (!totalValidation.valid) {
    throw new Error(totalValidation.message);
  }

  const parsedRows = rows.map((row, index) => ({
    name: String(row?.name ?? '').trim() || `শরীক ${index + 1}`,
    share: parseMetricNumber(row?.share),
  }));

  const rowValidation = validateMetricRows(parsedRows);
  if (!rowValidation.valid) {
    throw new Error(rowValidation.message);
  }

  const listedShare = parsedRows.reduce((sum, row) => sum + row.share, 0);

  if (listedShare !== metricTotal) {
    throw new Error(
      `মোট হিস্যার সঙ্গে শরীকদের হিস্যার যোগফল মিলছে না। বর্তমান যোগফল ${listedShare}।`
    );
  }

  const resultRows = parsedRows.map(row => {
    const percentage = (row.share / metricTotal) * 100;
    const allocatedLand = land * (row.share / metricTotal);

    return {
      name: row.name,
      share: row.share,
      percentage,
      allocatedLand,
    };
  });

  return {
    mode: 'metric',
    totalLand: land,
    totalShare: metricTotal,
    listedShare,
    rows: resultRows,
    allocatedLandTotal: resultRows.reduce(
      (sum, row) => sum + row.allocatedLand,
      0
    ),
  };
}
