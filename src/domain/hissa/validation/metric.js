import { parseFlexibleInteger } from "../input/parser.js";

export const METRIC_TOTAL = 1000;

export function validateMetricRow(row, index = 0) {
  const label =
    String(row?.name ?? "").trim() ||
    `শরীক ${String(index + 1)}`;

  const share = parseFlexibleInteger(row?.share, {
    allowBlank: false,
    min: 0,
    max: METRIC_TOTAL,
  });

  return {
    id: row?.id ?? `metric-${index + 1}`,
    name: label,
    share,
  };
}

export function validateMetricRows(rows) {
  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error("কমপক্ষে একজন শরীক দিতে হবে।");
  }

  const validatedRows = rows.map(validateMetricRow);

  const totalShare = validatedRows.reduce(
    (sum, row) => sum + row.share,
    0
  );

  if (totalShare > METRIC_TOTAL) {
    throw new Error(
      "মোট হিস্যা ১০০০-এর বেশি হয়েছে। ইনপুটে কোথাও ভুল থাকতে পারে। খতিয়ান বা মূল নথির তথ্য আবার যাচাই করুন।"
    );
  }

  if (totalShare <= 0) {
    throw new Error("মোট হিস্যা ০ হতে পারে না।");
  }

  return {
    rows: validatedRows,
    totalShare,
    maxShare: METRIC_TOTAL,
  };
}
