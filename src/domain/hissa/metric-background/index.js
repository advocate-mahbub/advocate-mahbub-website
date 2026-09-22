// Metric Mode background entry point.
// Intentionally NOT imported by the existing Hissa V1 index yet.

export { calculateMetric } from './metric.js';
export { parseMetricNumber, normalizeMetricNumber } from './parser.js';
export {
  METRIC_TOTAL_SHARE,
  validateMetricTotalShare,
  validateMetricRows,
} from './validation.js';
export {
  formatMetricShare,
  formatMetricPercent,
} from './formatter.js';
export { buildMetricExplanation } from './explanation.js';
