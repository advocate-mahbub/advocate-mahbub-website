      const inputs = document.querySelectorAll('.check-input');

      const checkedCount = document.querySelector('#checked-count');
      const yesCount = document.querySelector('#yes-count');
      const noCount = document.querySelector('#no-count');
      const unknownCount = document.querySelector('#unknown-count');

      const resetButton = document.querySelector('#reset-checklist');
      const resultButton = document.querySelector('#show-result');
      const resultBox = document.querySelector('#check-result');
      const resultText = document.querySelector('#check-result-text');

      
function updateResultVisuals(yes, no, unknown, checked) {
  const completedCount = document.querySelector('#result-completed-count');
  const resultYesCount = document.querySelector('#result-yes-count');
  const resultNoCount = document.querySelector('#result-no-count');
  const resultUnknownCount = document.querySelector('#result-unknown-count');

  const resultYesBar = document.querySelector('#result-yes-bar');
  const resultNoBar = document.querySelector('#result-no-bar');
  const resultUnknownBar = document.querySelector('#result-unknown-bar');

  const resultMeaning = document.querySelector('#result-meaning-text');

  if (!completedCount) return;

  completedCount.textContent = `${checked} / 28`;
  resultYesCount.textContent = yes;
  resultNoCount.textContent = no;
  resultUnknownCount.textContent = unknown;

  const yesPercent = (yes / 28) * 100;
  const noPercent = (no / 28) * 100;
  const unknownPercent = (unknown / 28) * 100;

  resultYesBar.style.width = `${yesPercent}%`;
  resultNoBar.style.width = `${noPercent}%`;
  resultUnknownBar.style.width = `${unknownPercent}%`;

  if (resultMeaning) {
    if (checked < 28) {
      resultMeaning.textContent =
        `আপনি এখন পর্যন্ত ${checked}টি checkpoint review করেছেন। বাকি ${28 - checked}টি checkpoint সম্পন্ন হলে আপনার পূর্ণ review summary এখানে দেখা যাবে।`;
    } else if (no > 0 || unknown > 0) {
      resultMeaning.textContent =
        `আপনার ২৮টি checkpoint review সম্পন্ন হয়েছে। ${no}টি বিষয়ে “না” এবং ${unknown}টি বিষয়ে “জানি না” নির্বাচন করা হয়েছে। এই বিষয়গুলো পরবর্তী legal review-এর সময় বিশেষভাবে যাচাই করা যেতে পারে।`;
    } else {
      resultMeaning.textContent =
        `আপনার ২৮টি checkpoint review সম্পন্ন হয়েছে এবং কোনো বিষয়ে “না” বা “জানি না” নির্বাচন করা হয়নি। প্রয়োজন অনুযায়ী supporting documents ও records আলাদাভাবে যাচাই করা যেতে পারে।`;
    }
  }
}

function updateSummary() {
        let checked = 0;
        let yes = 0;
        let no = 0;
        let unknown = 0;

        inputs.forEach((input) => {
          if (input.checked) {
            if (input.value === 'yes') yes++;
            if (input.value === 'no') no++;
            if (input.value === 'unknown') unknown++;
          }
        });

        checked = yes + no + unknown;

        checkedCount.textContent = `${checked}/28`;
        yesCount.textContent = yes;
        noCount.textContent = no;
        unknownCount.textContent = unknown;

  updateResultVisuals(yes, no, unknown, checked);
      }

      inputs.forEach((input) => {
        input.addEventListener('change', () => {
          updateSummary();
          resultBox.classList.remove('is-visible');
        });
      });

      resetButton.addEventListener('click', () => {
        inputs.forEach((input) => {
          input.checked = false;
        });

        resultBox.classList.remove('is-visible');
        updateSummary();
      });

      resultButton.addEventListener('click', () => {
        let yes = 0;
        let no = 0;
        let unknown = 0;

        inputs.forEach((input) => {
          if (!input.checked) return;

          if (input.value === 'yes') yes++;
          if (input.value === 'no') no++;
          if (input.value === 'unknown') unknown++;
        });

        const checked = yes + no + unknown;
        const remaining = 28 - checked;

        if (remaining > 0) {
          resultText.textContent =
            `আপনি এখন পর্যন্ত ${checked}টি বিষয় যাচাই করেছেন। আরও ${remaining}টি বিষয়ের উত্তর দেওয়া বাকি।`;
        } else {
          resultText.textContent =
            `আপনার ২৮টি checkpoint-এর review সম্পন্ন হয়েছে। আপনার উত্তরের মধ্যে ${no}টি বিষয়ে "না" এবং ${unknown}টি বিষয়ে "জানি না" নির্বাচন করা হয়েছে। এগুলো পরবর্তী legal review-এর জন্য বিশেষভাবে দেখা যেতে পারে।`;
        }

        resultBox.classList.add('is-visible');

        resultBox.scrollIntoView({
          behavior: 'smooth',
          block: 'center'
        });
      });

      updateSummary();
