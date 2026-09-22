// Isolated Metric Mode formatting helpers.

export function formatMetricShare(value) {
  return Number(value).toLocaleString('bn-BD', {
    maximumFractionDigits: 4,
  });
}

export function formatMetricPercent(value) {
  return `${Number(value).toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 4,
  })}%`;
}
