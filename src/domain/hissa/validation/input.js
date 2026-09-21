export function validateTotalLand(totalLand) {
  const value = Number(totalLand);

  if (!Number.isFinite(value) || value <= 0) {
    return {
      valid: false,
      message: "মোট জমির পরিমাণ ০-এর বেশি হতে হবে।",
    };
  }

  return { valid: true };
}

export function validateRows(rows = []) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return {
      valid: false,
      message: "কমপক্ষে একজন শরিক প্রয়োজন।",
    };
  }

  const hasPositiveShare = rows.some(
    (row) => BigInt(row.shareTil ?? 0) > 0n
  );

  if (!hasPositiveShare) {
    return {
      valid: false,
      message: "কমপক্ষে একজন শরিকের হিস্যা দিতে হবে।",
    };
  }

  return { valid: true };
}
