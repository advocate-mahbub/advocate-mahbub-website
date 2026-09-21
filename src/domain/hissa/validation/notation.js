export const NOTATION_LIMITS = Object.freeze({
  anna: { min: 0, max: 15 },
  gonda: { min: 0, max: 19 },
  kora: { min: 0, max: 3 },
  kranti: { min: 0, max: 19 },
  til: { min: 0, max: 19 },
});

export function validateNotation(input = {}) {
  for (const [field, limits] of Object.entries(NOTATION_LIMITS)) {
    const value = Number(input[field] ?? 0);

    if (
      !Number.isInteger(value) ||
      value < limits.min ||
      value > limits.max
    ) {
      return {
        valid: false,
        field,
        message: `${field} এর মান ${limits.min} থেকে ${limits.max} এর মধ্যে হতে হবে।`,
      };
    }
  }

  return { valid: true };
}
