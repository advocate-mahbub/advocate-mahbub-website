export function buildExplanation(result) {
  return {
    mode: result.mode,

    steps: [
      "প্রতিটি শরিকের হিস্যা internal Til unit-এ normalize করা হয়েছে।",
      "তালিকাভুক্ত সব শরিকের normalized হিস্যা যোগ করে Total Listed Share নির্ধারণ করা হয়েছে।",
      "প্রতিটি শরিকের Allocation Ratio = Individual Share ÷ Total Listed Share।",
      "Allocated Land = Total Land × Allocation Ratio।",
    ],
  };
}
