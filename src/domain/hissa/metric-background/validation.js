// Isolated Metric Mode validation.
// V1 structure assumes a 1000-based metric share system.

export const METRIC_TOTAL_SHARE = 1000;

export function validateMetricTotalShare(value) {
  if (value !== METRIC_TOTAL_SHARE) {
    return {
      valid: false,
      message: 'Metric Mode-এ মোট হিস্যা ১০০০ হতে হবে।',
    };
  }

  return { valid: true, message: '' };
}

export function validateMetricRows(rows) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return {
      valid: false,
      message: 'অন্তত একজন শরিকের হিস্যা দিতে হবে।',
    };
  }

  for (const row of rows) {
    if (!row || !Number.isFinite(row.share) || row.share < 0) {
      return {
        valid: false,
        message: 'প্রতিটি শরিকের হিস্যা শূন্য বা তার বেশি হতে হবে।',
      };
    }
  }

  return { valid: true, message: '' };
}
