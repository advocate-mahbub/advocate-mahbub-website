// Isolated Metric Mode parser.
// Not imported by Normal / GroupLine.
// Supports English and Bengali decimal digits.

const BANGLA_DIGITS = '০১২৩৪৫৬৭৮৯';
const ENGLISH_DIGITS = '0123456789';

export function normalizeMetricNumber(value) {
  if (value === null || value === undefined) return '';

  return String(value)
    .trim()
    .replace(/[০-৯]/g, ch => ENGLISH_DIGITS[BANGLA_DIGITS.indexOf(ch)])
    .replace(/,/g, '');
}

export function parseMetricNumber(value) {
  const normalized = normalizeMetricNumber(value);

  if (normalized === '') return null;
  if (!/^\d+(?:\.\d+)?$/.test(normalized)) return null;

  const number = Number(normalized);
  return Number.isFinite(number) ? number : null;
}
