export function formatLand(
  value,
  maximumFractionDigits = 6
) {
  return Number(value).toLocaleString("en-US", {
    minimumFractionDigits: 0,
    maximumFractionDigits,
  });
}

export function formatPercent(value) {
  return `${(Number(value) * 100).toFixed(4)}%`;
}
