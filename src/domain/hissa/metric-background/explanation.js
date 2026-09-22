// Isolated Metric Mode calculation trace.

export function buildMetricExplanation(result) {
  const lines = [
    `মোট হিস্যা ${result.totalShare.toLocaleString('bn-BD')} ধরা হয়েছে।`,
    `শরিকদের হিস্যার যোগফল ${result.listedShare.toLocaleString('bn-BD')}।`,
    'প্রতিটি শরিকের হিস্যার অনুপাত অনুযায়ী মোট জমির অংশ নির্ধারণ করা হয়েছে।',
  ];

  return lines.join('\n');
}
