import { validateMetricRows } from "../validation/metric.js";
import { parseFlexibleInteger } from "../input/parser.js";

export const METRIC_TOTAL = 1000;

function round(value, digits = 8) {
  const factor = 10 ** digits;
  return Math.round((value + Number.EPSILON) * factor) / factor;
}

export function calculateMetric(payload) {
  const totalLand = Number(payload?.totalLand);

  if (!Number.isFinite(totalLand) || totalLand <= 0) {
    throw new Error(
      "মোট জমির পরিমাণ বসানো হয়নি। পরিমাণ বসিয়ে নিচের “হিসাব করুন” বাটনে আবার চাপুন।"
    );
  }

  const validated = validateMetricRows(payload?.rows);

  const rows = validated.rows.map((row) => {
    const ratio =
      row.share / validated.totalShare;

    return {
      ...row,
      ratio: round(ratio, 10),
      percentage: round(ratio * 100, 8),
      allocatedLand: round(totalLand * ratio, 8),
    };
  });

  return {
    mode: "metric",
    totalLand,
    totalShare: validated.totalShare,
    maxShare: METRIC_TOTAL,
    rows,
    explanation: [
      "Metric Mode-এ প্রতিটি শরীকের শেয়ার ১০০০-এর ভিত্তিতে হিসাব করা হয়।",
      `মোট তালিকাভুক্ত শেয়ার: ${validated.totalShare}।`,
      "প্রত্যেক শরীকের অংশ = শরীকের শেয়ার ÷ মোট তালিকাভুক্ত শেয়ার।",
      "বরাদ্দ জমি = মোট জমি × শরীকের অংশ।",
    ],
  };
}

export function parseMetricShare(value) {
  return parseFlexibleInteger(value, {
    allowBlank: false,
    min: 0,
    max: METRIC_TOTAL,
  });
}
