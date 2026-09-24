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
      message: "কমপক্ষে একজন শরীক প্রয়োজন।",
    };
  }

  const hasPositiveShare = rows.some(
    (row) => BigInt(row.shareTil ?? 0) > 0n
  );

  if (!hasPositiveShare) {
    return {
      valid: false,
      message: "কমপক্ষে একজন শরীকের হিস্যা দিতে হবে।",
    };
  }

  return { valid: true };
}

export const FULL_NORMAL_SHARE_TIL = 76800n;

export function getTotalShareTil(rows = []) {
  return rows.reduce(
    (sum, row) => sum + BigInt(row.shareTil ?? 0),
    0n
  );
}

export function validateNormalTotalShare(totalShareTil) {
  const total = BigInt(totalShareTil ?? 0);

  if (total < FULL_NORMAL_SHARE_TIL) {
    return {
      valid: false,
      message:
        "জমি ১৬ আনার কম! ভালো করে যাচাই করুন। খতিয়ানে কোনো অংশ বাদ পড়েছে কি না, ভালো করে দেখুন!",
    };
  }

  if (total > FULL_NORMAL_SHARE_TIL) {
    return {
      valid: false,
      message:
        "জমি ১৬ আনার বেশি! ভালো করে যাচাই করুন। খতিয়ানে ভুল আছে কি না, ভালো করে দেখুন!",
    };
  }

  return { valid: true };
}

export function getGroupLineTotalShareNote(totalShareTil) {
  const total = BigInt(totalShareTil ?? 0);

  if (total < FULL_NORMAL_SHARE_TIL) {
    return "নোট: প্রদত্ত শরীকদের মোট হিস্যা ১৬ আনার কম। হিসাব দেওয়া হয়েছে, তবে খতিয়ানের সম্পূর্ণ হিস্যা দেওয়া হয়েছে কি না যাচাই করুন।";
  }

  if (total > FULL_NORMAL_SHARE_TIL) {
    return "নোট: প্রদত্ত শরীকদের মোট হিস্যা ১৬ আনার বেশি। হিসাব দেওয়া হয়েছে, তবে ইনপুটের হিস্যা ও খতিয়ানের তথ্য ভালোভাবে যাচাই করুন।";
  }

  return "";
}
