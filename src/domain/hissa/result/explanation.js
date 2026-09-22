export function buildExplanation(result) {
  return {
    mode: result.mode,

    steps: [
      "প্রতিটি শরিকের হিস্যা internal Til unit-এ normalize করা হয়েছে।",
      "তালিকাভুক্ত সব শরিকের normalized হিস্যা যোগ করে মোট শেয়ার নির্ধারণ করা হয়েছে।",
      "প্রতিটি শরিকের হিস্যার অংশ Ratio = Individual Share ÷ মোট শেয়ার।",
      "Allocated Land = Total Land × হিস্যার অংশ Ratio।",
    ],
  };
}
