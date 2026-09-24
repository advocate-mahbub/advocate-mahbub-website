const DIGIT_MAP = new Map([
  ["০", "0"], ["১", "1"], ["২", "2"], ["৩", "3"], ["৪", "4"],
  ["৫", "5"], ["৬", "6"], ["৭", "7"], ["৮", "8"], ["৯", "9"],

  // Arabic-Indic digits
  ["٠", "0"], ["١", "1"], ["٢", "2"], ["٣", "3"], ["٤", "4"],
  ["٥", "5"], ["٦", "6"], ["٧", "7"], ["٨", "8"], ["٩", "9"],

  // Extended Arabic-Indic digits
  ["۰", "0"], ["۱", "1"], ["۲", "2"], ["۳", "3"], ["۴", "4"],
  ["۵", "5"], ["۶", "6"], ["۷", "7"], ["۸", "8"], ["۹", "9"],
]);

export function normalizeDigits(value) {
  return String(value ?? "")
    .replace(/[০-৯٠-٩۰-۹]/g, (digit) => DIGIT_MAP.get(digit) ?? digit);
}

export function parseFlexibleInteger(value, {
  allowBlank = false,
  min = 0,
  max = Number.MAX_SAFE_INTEGER,
} = {}) {
  const normalized = normalizeDigits(value).trim();

  if (!normalized) {
    if (allowBlank) return null;
    throw new Error("সংখ্যার ঘরটি পূরণ করুন।");
  }

  if (!/^\d+$/.test(normalized)) {
    throw new Error("শুধু সংখ্যা ব্যবহার করুন।");
  }

  const parsed = Number(normalized);

  if (!Number.isSafeInteger(parsed)) {
    throw new Error("সংখ্যাটি গ্রহণযোগ্য সীমার মধ্যে নেই।");
  }

  if (parsed < min || parsed > max) {
    throw new Error(`সংখ্যাটি ${min} থেকে ${max}-এর মধ্যে হতে হবে।`);
  }

  return parsed;
}
