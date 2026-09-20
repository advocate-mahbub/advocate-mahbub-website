import {
  propertyTypes,
  decisionIntents,
  questions,
  answers,
} from '../data/property-risk-checker.js';


const STORAGE_KEY =
  'mahbuburrahman_property_risk_checker_v1';


const state = {
  step: 0,

  propertyType: '',

  decisionIntent: '',

  answers: {},

  result: null,
};


const screen =
  document.querySelector('#risk-screen');

const navigation =
  document.querySelector('#risk-navigation');

const progressBar =
  document.querySelector('#progress-bar');

const progressLabel =
  document.querySelector('#progress-label');

const progressCount =
  document.querySelector('#progress-count');


const TOTAL_STEPS =
  8;


/* =========================================================
   STORAGE
   ========================================================= */

function saveState() {

  localStorage.setItem(
    STORAGE_KEY,
    JSON.stringify(state)
  );

}


function clearState() {

  localStorage.removeItem(
    STORAGE_KEY
  );

}


/* =========================================================
   PROGRESS
   ========================================================= */

function updateProgress() {

  const current =
    Math.min(
      state.step,
      TOTAL_STEPS
    );

  const percentage =
    (current / TOTAL_STEPS) * 100;


  progressBar.style.width =
    `${percentage}%`;


  progressCount.textContent =
    `${current} / ${TOTAL_STEPS}`;


  if (state.step === 0) {

    progressLabel.textContent =
      'শুরু';

  } else if (state.step === TOTAL_STEPS) {

    progressLabel.textContent =
      'Result';

  } else {

    progressLabel.textContent =
      'Property Risk Check';

  }

}


/* =========================================================
   ESCAPE
   ========================================================= */

function escapeHTML(value) {

  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');

}


/* =========================================================
   SCREEN 0 — INTRO
   ========================================================= */

function renderIntro() {

  screen.innerHTML = `
    <p class="screen-kicker">
      PROPERTY RISK CHECKER
    </p>

    <h2 class="screen-title">
      Property নিয়ে সিদ্ধান্ত নেওয়ার
      আগে ঝুঁকিটা বুঝুন।
    </h2>

    <p class="screen-description">
      কয়েকটি প্রশ্নের মাধ্যমে আপনার property situation-এর
      গুরুত্বপূর্ণ information gap চিহ্নিত করুন।
    </p>

    <div class="result-cta">
      <h3>
        কীভাবে কাজ করবে?
      </h3>

      <p>
        Property type এবং আপনার decision intent জানান।
        তারপর কয়েকটি structured question-এর উত্তর দিন।
        শেষে আপনি একটি preliminary attention result পাবেন।
      </p>
    </div>
  `;


  navigation.innerHTML = `
    <span></span>

    <button
      type="button"
      class="next-button"
      id="start-button"
    >
      Risk Check শুরু করুন
    </button>
  `;


  document
    .querySelector('#start-button')
    .addEventListener(
      'click',
      () => {

        state.step = 1;

        saveState();

        render();

      }
    );

}


/* =========================================================
   SCREEN 1 — PROPERTY TYPE
   ========================================================= */

function renderPropertyType() {

  screen.innerHTML = `
    <p class="screen-kicker">
      01 / 08
    </p>

    <h2 class="screen-title">
      আপনার property-এর ধরন কোনটি?
    </h2>

    <div class="option-grid">

      ${propertyTypes
        .map(
          (item) => `
            <button
              type="button"
              class="option-button ${
                state.propertyType === item.value
                  ? 'selected'
                  : ''
              }"
              data-property="${item.value}"
            >
              ${escapeHTML(item.label)}
            </button>
          `
        )
        .join('')}

    </div>
  `;


  screen
    .querySelectorAll('[data-property]')
    .forEach((button) => {

      button.addEventListener(
        'click',
        () => {

          state.propertyType =
            button.dataset.property;

          saveState();

          render();

        }
      );

    });


  renderNavigation(
    true,
    Boolean(state.propertyType)
  );

}


/* =========================================================
   SCREEN 2 — DECISION INTENT
   ========================================================= */

function renderDecisionIntent() {

  screen.innerHTML = `
    <p class="screen-kicker">
      02 / 08
    </p>

    <h2 class="screen-title">
      Property নিয়ে আপনি কোন
      সিদ্ধান্ত নিতে যাচ্ছেন?
    </h2>

    <div class="option-grid">

      ${decisionIntents
        .map(
          (item) => `
            <button
              type="button"
              class="option-button ${
                state.decisionIntent === item.value
                  ? 'selected'
                  : ''
              }"
              data-intent="${item.value}"
            >
              ${escapeHTML(item.label)}
            </button>
          `
        )
        .join('')}

    </div>
  `;


  screen
    .querySelectorAll('[data-intent]')
    .forEach((button) => {

      button.addEventListener(
        'click',
        () => {

          state.decisionIntent =
            button.dataset.intent;

          saveState();

          render();

        }
      );

    });


  renderNavigation(
    true,
    Boolean(state.decisionIntent)
  );

}


/* =========================================================
   SCREEN 3–8 — QUESTIONS
   ========================================================= */

function renderQuestion() {

  const questionIndex =
    state.step - 3;

  const question =
    questions[questionIndex];


  if (!question) {

    state.step = 10;

    render();

    return;

  }


  const currentAnswer =
    state.answers[question.id] || '';


  screen.innerHTML = `
    <p class="screen-kicker">
      ${String(state.step).padStart(2, '0')} / 08
    </p>

    <h2 class="screen-title">
      ${escapeHTML(question.label)}
    </h2>

    <p class="screen-description">
      আপনার জানা information অনুযায়ী সবচেয়ে
      উপযুক্ত উত্তরটি নির্বাচন করুন।
    </p>

    <div class="answer-options">

      ${answers
        .map(
          (answer) => `
            <button
              type="button"
              class="answer-button ${
                currentAnswer === answer.value
                  ? 'selected'
                  : ''
              }"
              data-answer="${answer.value}"
            >
              ${escapeHTML(answer.label)}
            </button>
          `
        )
        .join('')}

    </div>
  `;


  screen
    .querySelectorAll('[data-answer]')
    .forEach((button) => {

      button.addEventListener(
        'click',
        () => {

          state.answers[question.id] =
            button.dataset.answer;

          saveState();

          render();

        }
      );

    });


  renderNavigation(
    true,
    Boolean(currentAnswer)
  );

}


/* =========================================================
   REVIEW
   ========================================================= */

function renderReview() {

  const rows =
    questions
      .map((question) => {

        const value =
          state.answers[question.id];

        const answer =
          answers.find(
            (item) =>
              item.value === value
          );


        return `
          <div class="review-item">

            <span>
              ${escapeHTML(
                question.shortLabel
              )}
            </span>

            <span class="review-value">
              ${
                answer
                  ? escapeHTML(answer.label)
                  : 'নির্বাচন করা হয়নি'
              }
            </span>

          </div>
        `;

      })
      .join('');


  screen.innerHTML = `
    <p class="screen-kicker">
      REVIEW
    </p>

    <h2 class="screen-title">
      আপনার উত্তরগুলো দেখুন।
    </h2>

    <p class="screen-description">
      Result তৈরি করার আগে আপনার দেওয়া
      information একবার দেখে নিন।
    </p>

    <div class="review-list">
      ${rows}
    </div>
  `;


  navigation.innerHTML = `
    <button
      type="button"
      id="review-back"
    >
      ← উত্তর পরিবর্তন করুন
    </button>

    <button
      type="button"
      class="next-button"
      id="calculate-result"
    >
      Result দেখুন
    </button>
  `;


  document
    .querySelector('#review-back')
    .addEventListener(
      'click',
      () => {

        state.step = 8;

        render();

      }
    );


  document
    .querySelector('#calculate-result')
    .addEventListener(
      'click',
      () => {

        calculateResult();

        state.step = 10;

        saveState();

        render();

      }
    );

}


/* =========================================================
   RESULT ENGINE
   ========================================================= */

function calculateResult() {

  let score = 0;

  const flags = [];


  questions.forEach((question) => {

    const value =
      state.answers[question.id];


    if (
      question.type === 'verification'
    ) {

      if (value === 'no') {

        score += 2;

        flags.push(
          question.id
        );

      }

      if (value === 'not-sure') {

        score += 1;

        flags.push(
          question.id
        );

      }

    }


    if (
      question.type === 'dispute'
    ) {

      if (value === 'yes') {

        score += 2;

        flags.push(
          question.id
        );

      }

      if (value === 'not-sure') {

        score += 1;

        flags.push(
          question.id
        );

      }

    }


    if (
      question.type === 'context'
    ) {

      if (
        value === 'yes' ||
        value === 'not-sure'
      ) {

        flags.push(
          question.id
        );

      }

    }

  });


  let level =
    'low';


  if (score >= 4) {

    level = 'high';

  } else if (score >= 1) {

    level = 'needs-review';

  }


  state.result = {
    score,
    level,
    flags,
    calculatedAt:
      new Date().toISOString(),
  };


  saveState();

}


/* =========================================================
   RESULT CONTENT
   ========================================================= */

function getResultCopy(level) {

  if (level === 'low') {

    return {
      badge: 'LOW ATTENTION',

      title:
        'এই screening-এ বড় কোনো information gap ধরা পড়েনি।',

      explanation:
        'আপনার দেওয়া উত্তরের ভিত্তিতে এই preliminary screening-এ বড় কোনো information gap ধরা পড়েনি। তবুও property decision-এর আগে relevant documents ও records যাচাই করা গুরুত্বপূর্ণ।',

    };

  }


  if (level === 'high') {

    return {
      badge: 'HIGH ATTENTION',

      title:
        'আরও বিস্তারিতভাবে বিষয়গুলো যাচাই করা প্রয়োজন।',

      explanation:
        'আপনার উত্তরের মধ্যে এক বা একাধিক গুরুত্বপূর্ণ information gap পাওয়া গেছে। Property decision নেওয়ার আগে সংশ্লিষ্ট documents, records এবং facts আরও বিস্তারিতভাবে review করা প্রয়োজন হতে পারে।',

    };

  }


  return {
    badge: 'NEEDS REVIEW',

    title:
      'কিছু গুরুত্বপূর্ণ information এখনো পরিষ্কার নয়।',

    explanation:
      'আপনার property situation-এর কিছু গুরুত্বপূর্ণ information এখনো পরিষ্কার নয়। Decision নেওয়ার আগে missing information এবং relevant documents review করুন।',

  };

}


/* =========================================================
   RESULT SCREEN
   ========================================================= */

function renderResult() {

  const result =
    state.result;


  if (!result) {

    calculateResult();

  }


  const copy =
    getResultCopy(
      state.result.level
    );


  const flaggedQuestions =
    questions.filter(
      (question) =>
        state.result.flags.includes(
          question.id
        )
    );


  const checks =
    flaggedQuestions.length
      ? flaggedQuestions
      : questions.slice(0, 2);


  screen.innerHTML = `
    <div class="result-header">

      <span class="result-badge">
        ${copy.badge}
      </span>

      <h2 class="screen-title">
        ${copy.title}
      </h2>

      <p class="result-explanation">
        ${copy.explanation}
      </p>

    </div>


    <div class="result-section">

      <h3>
        এখন যেগুলো দেখবেন
      </h3>

      <ul class="result-check-list">

        ${checks
          .map(
            (question) => `
              <li>
                ${escapeHTML(
                  question.shortLabel
                )}
              </li>
            `
          )
          .join('')}

      </ul>

    </div>


    <div class="result-cta">

      <h3>
        Property কেনার আগে ২১টি Legal Checkpoint
      </h3>

      <p>
        আপনার property review আরও structured করতে
        ২১টি Legal Checkpoint-এর checklist ব্যবহার করুন।
      </p>

      <a href="/resources/property-legal-checklist/">
        Free Legal Checklist
      </a>

    </div>


    <div class="result-cta">

      <h3>
        আপনার বিষয়টি আলোচনা করুন
      </h3>

      <p>
        আপনার result, questions এবং প্রয়োজনীয় documents
        নিয়ে structured legal discussion-এর জন্য যোগাযোগ করুন।
      </p>

      <a href="/consultation/">
        আমার বিষয়টি আলোচনা করুন
      </a>

    </div>


    <p class="result-disclaimer">
      এই result একটি preliminary awareness output।
      এটি formal legal opinion, legal advice বা
      কোনো নির্দিষ্ট legal outcome-এর guarantee নয়।
    </p>
  `;


  navigation.innerHTML = `
    <button
      type="button"
      id="restart-checker"
    >
      আবার শুরু করুন
    </button>

    <span></span>
  `;


  document
    .querySelector('#restart-checker')
    .addEventListener(
      'click',
      () => {

        clearState();

        window.location.reload();

      }
    );

}


/* =========================================================
   NAVIGATION
   ========================================================= */

function renderNavigation(
  showBack,
  canContinue
) {

  navigation.innerHTML = `

    ${
      showBack
        ? `
          <button
            type="button"
            id="back-button"
          >
            ← Back
          </button>
        `
        : `<span></span>`
    }


    <button
      type="button"
      class="next-button"
      id="next-button"
      ${canContinue ? '' : 'disabled'}
    >
      Next →
    </button>

  `;


  const backButton =
    document.querySelector(
      '#back-button'
    );


  if (backButton) {

    backButton.addEventListener(
      'click',
      () => {

        state.step -= 1;

        render();

      }
    );

  }


  const nextButton =
    document.querySelector(
      '#next-button'
    );


  if (nextButton) {

    nextButton.addEventListener(
      'click',
      () => {

        if (!canContinue) {

          return;

        }


        state.step += 1;

        saveState();

        render();

      }
    );

  }

}


/* =========================================================
   MAIN RENDER
   ========================================================= */

function render() {

  updateProgress();


  if (state.step === 0) {

    renderIntro();

    return;

  }


  if (state.step === 1) {

    renderPropertyType();

    return;

  }


  if (state.step === 2) {

    renderDecisionIntent();

    return;

  }


  if (
    state.step >= 3 &&
    state.step <= 8
  ) {

    renderQuestion();

    return;

  }


  if (state.step === 9) {

    renderReview();

    return;

  }


  if (state.step === 10) {

    renderResult();

  }

}


/* =========================================================
   START
   ========================================================= */

render();