#!/usr/bin/env bash

set -e

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$ROOT/backups/hissa-sprint2"

echo "=========================================="
echo "Hissa Calculator V1 - Sprint 2"
echo "Creating interactive UI..."
echo "=========================================="

mkdir -p "$BACKUP_DIR"

# --------------------------------------------------
# 1. Backup existing Sprint 2 files if any
# --------------------------------------------------

for path in \
  "src/pages/tools/hissa-calculator.astro" \
  "src/scripts/hissa-calculator.js" \
  "src/styles/hissa-calculator.css"
do
  if [ -e "$ROOT/$path" ]; then
    echo "Backing up existing: $path"

    filename="$(basename "$path")"

    cp "$ROOT/$path" \
      "$BACKUP_DIR/${filename}.${STAMP}.bak"
  fi
done

# --------------------------------------------------
# 2. Create Astro page
# --------------------------------------------------

cat > src/pages/tools/hissa-calculator.astro <<'EOF'
---
import "../../styles/hissa-calculator.css";
---

<html lang="bn">
  <head>
    <meta charset="UTF-8" />
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1"
    />

    <title>Hissa Calculator | Mahbubur Rahman</title>

    <meta
      name="description"
      content="হিস্যা অনুযায়ী জমির আনুপাতিক অংশ হিসাব করার জন্য Hissa Calculator।"
    />
  </head>

  <body>
    <main class="hissa-page">
      <section class="hissa-hero">
        <div class="hissa-container">
          <p class="hissa-kicker">
            PROPERTY LEGAL TOOL
          </p>

          <h1>
            Hissa <span>Calculator</span>
          </h1>

          <p class="hissa-hero-text">
            শরিকদের হিস্যা অনুযায়ী জমির আনুপাতিক অংশ
            সহজভাবে হিসাব করুন।
          </p>

          <p class="hissa-hero-note">
            এটি একটি mathematical calculation tool।
            এটি কোনো আইনগত মালিকানা বা title determination করে না।
          </p>
        </div>
      </section>

      <section class="hissa-workspace">
        <div class="hissa-container">

          <!-- MODE SWITCH -->

          <div class="hissa-mode-switch" role="tablist">
            <button
              type="button"
              class="hissa-mode-button is-active"
              data-mode="normal"
              role="tab"
              aria-selected="true"
            >
              Normal Mode
            </button>

            <button
              type="button"
              class="hissa-mode-button"
              data-mode="groupline"
              role="tab"
              aria-selected="false"
            >
              GroupLine Mode
            </button>
          </div>

          <!-- CALCULATOR CARD -->

          <div class="hissa-card">

            <div class="hissa-card-header">
              <div>
                <p class="hissa-section-kicker">
                  CALCULATION INPUT
                </p>

                <h2>
                  মোট জমি ও শরিকদের হিস্যা দিন
                </h2>
              </div>

              <div
                class="hissa-mode-badge"
                data-active-mode
              >
                Normal Mode
              </div>
            </div>

            <!-- TOTAL LAND -->

            <div class="hissa-total-land">
              <label for="hissa-total-land">
                মোট জমি
              </label>

              <div class="hissa-land-input">
                <input
                  id="hissa-total-land"
                  type="number"
                  min="0"
                  step="any"
                  inputmode="decimal"
                  placeholder="যেমন: 31.5"
                />

                <select id="hissa-land-unit">
                  <option value="শতক">শতক</option>
                  <option value="একর">একর</option>
                  <option value="অযুতাংশ">অযুতাংশ</option>
                </select>
              </div>
            </div>

            <!-- SHAREHOLDERS -->

            <div class="hissa-share-header">
              <div>
                <p class="hissa-section-kicker">
                  SHAREHOLDERS
                </p>

                <h3>
                  শরিকদের হিস্যা
                </h3>
              </div>

              <button
                type="button"
                class="hissa-add-button"
                id="hissa-add-row"
              >
                + শরিক যোগ করুন
              </button>
            </div>

            <div
              id="hissa-rows"
              class="hissa-rows"
            ></div>

            <p
              id="hissa-error"
              class="hissa-error"
              role="alert"
              hidden
            ></p>

            <div class="hissa-actions">
              <button
                type="button"
                class="hissa-calculate-button"
                id="hissa-calculate"
              >
                হিসাব করুন
              </button>

              <button
                type="button"
                class="hissa-reset-button"
                id="hissa-reset"
              >
                Reset
              </button>
            </div>

          </div>

          <!-- RESULT -->

          <section
            id="hissa-result"
            class="hissa-result"
            hidden
            aria-live="polite"
          >
            <div class="hissa-result-header">
              <div>
                <p class="hissa-section-kicker">
                  CALCULATION RESULT
                </p>

                <h2>
                  আপনার হিস্যার ফলাফল
                </h2>
              </div>

              <div
                class="hissa-mode-badge"
                data-result-mode
              >
                Normal Mode
              </div>
            </div>

            <div
              id="hissa-result-rows"
              class="hissa-result-rows"
            ></div>

            <div class="hissa-trace">
              <button
                type="button"
                class="hissa-trace-toggle"
                id="hissa-trace-toggle"
                aria-expanded="false"
              >
                হিসাব কীভাবে হলো?
                <span>+</span>
              </button>

              <div
                id="hissa-trace-content"
                class="hissa-trace-content"
                hidden
              >
                <div id="hissa-trace-list"></div>
              </div>
            </div>

            <div class="hissa-disclaimer">
              <strong>গুরুত্বপূর্ণ:</strong>
              এই calculator হিস্যার mathematical allocation
              হিসাব করে। এটি কোনো দলিল, খতিয়ান, উত্তরাধিকার,
              title, possession বা আইনগত মালিকানা নির্ধারণ করে না।
            </div>
          </section>

        </div>
      </section>
    </main>

    <script src="../../scripts/hissa-calculator.js"></script>
  </body>
</html>
EOF

# --------------------------------------------------
# 3. Browser interaction layer
# --------------------------------------------------

cat > src/scripts/hissa-calculator.js <<'EOF'
import {
  calculateNormal,
  calculateGroupLine,
  buildExplanation,
  formatLand,
  formatPercent,
} from "../domain/hissa/index.js";

const state = {
  activeMode: "normal",

  normal: {
    totalLand: "",
    landUnit: "শতক",
    rows: [],
  },

  groupline: {
    totalLand: "",
    landUnit: "শতক",
    rows: [],
  },
};

const elements = {
  modeButtons: document.querySelectorAll(
    ".hissa-mode-button"
  ),

  activeMode: document.querySelector(
    "[data-active-mode]"
  ),

  resultMode: document.querySelector(
    "[data-result-mode]"
  ),

  totalLand: document.querySelector(
    "#hissa-total-land"
  ),

  landUnit: document.querySelector(
    "#hissa-land-unit"
  ),

  rows: document.querySelector(
    "#hissa-rows"
  ),

  error: document.querySelector(
    "#hissa-error"
  ),

  addRow: document.querySelector(
    "#hissa-add-row"
  ),

  calculate: document.querySelector(
    "#hissa-calculate"
  ),

  reset: document.querySelector(
    "#hissa-reset"
  ),

  result: document.querySelector(
    "#hissa-result"
  ),

  resultRows: document.querySelector(
    "#hissa-result-rows"
  ),

  traceToggle: document.querySelector(
    "#hissa-trace-toggle"
  ),

  traceContent: document.querySelector(
    "#hissa-trace-content"
  ),

  traceList: document.querySelector(
    "#hissa-trace-list"
  ),
};

const BANGLA_DIGITS = "০১২৩৪৫৬৭৮৯";

function banglaNumber(value) {
  return String(value).replace(
    /\d/g,
    (digit) => BANGLA_DIGITS[digit]
  );
}

function createRow() {
  return {
    id: crypto.randomUUID(),
    name: "",
    anna: "",
    gonda: "",
    kora: "",
    kranti: "",
    til: "",
  };
}

function getCurrentState() {
  return state[state.activeMode];
}

function saveInputsToState() {
  const current = getCurrentState();

  current.totalLand =
    elements.totalLand.value;

  current.landUnit =
    elements.landUnit.value;

  const rowElements =
    elements.rows.querySelectorAll(
      ".hissa-row"
    );

  current.rows =
    Array.from(rowElements).map((row) => ({
      id: row.dataset.id,

      name:
        row.querySelector("[data-field='name']")
          ?.value ?? "",

      anna:
        row.querySelector("[data-field='anna']")
          ?.value ?? "",

      gonda:
        row.querySelector("[data-field='gonda']")
          ?.value ?? "",

      kora:
        row.querySelector("[data-field='kora']")
          ?.value ?? "",

      kranti:
        row.querySelector("[data-field='kranti']")
          ?.value ?? "",

      til:
        row.querySelector("[data-field='til']")
          ?.value ?? "",
    }));
}

function restoreCurrentState() {
  const current = getCurrentState();

  elements.totalLand.value =
    current.totalLand ?? "";

  elements.landUnit.value =
    current.landUnit ?? "শতক";

  elements.rows.innerHTML = "";

  if (!current.rows.length) {
    current.rows.push(createRow());
  }

  current.rows.forEach(renderRow);
}

function renderRow(row) {
  const wrapper =
    document.createElement("div");

  wrapper.className = "hissa-row";
  wrapper.dataset.id = row.id;

  wrapper.innerHTML = `
    <div class="hissa-row-top">
      <div class="hissa-name-field">
        <label>শরিক / Group</label>

        <input
          type="text"
          data-field="name"
          value="${escapeHtml(row.name)}"
          placeholder="নাম লিখুন"
        />
      </div>

      <button
        type="button"
        class="hissa-remove-button"
        data-remove-row
        aria-label="এই শরিক বাদ দিন"
      >
        ×
      </button>
    </div>

    <div class="hissa-unit-grid">
      ${unitInput("anna", "আনা", row.anna)}
      ${unitInput("gonda", "গন্ডা", row.gonda)}
      ${unitInput("kora", "কড়া", row.kora)}
      ${unitInput("kranti", "ক্রান্তি", row.kranti)}
      ${unitInput("til", "তিল", row.til)}
    </div>
  `;

  elements.rows.appendChild(wrapper);
}

function unitInput(field, label, value) {
  return `
    <label class="hissa-unit-field">
      <span>${label}</span>

      <input
        type="number"
        min="0"
        step="1"
        inputmode="numeric"
        data-field="${field}"
        value="${escapeHtml(value)}"
        placeholder="0"
      />
    </label>
  `;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function showError(message) {
  elements.error.textContent = message;
  elements.error.hidden = false;
}

function clearError() {
  elements.error.textContent = "";
  elements.error.hidden = true;
}

function setMode(mode) {
  saveInputsToState();

  state.activeMode = mode;

  elements.modeButtons.forEach(
    (button) => {
      const active =
        button.dataset.mode === mode;

      button.classList.toggle(
        "is-active",
        active
      );

      button.setAttribute(
        "aria-selected",
        String(active)
      );
    }
  );

  const label =
    mode === "normal"
      ? "Normal Mode"
      : "GroupLine Mode";

  elements.activeMode.textContent =
    label;

  elements.resultMode.textContent =
    label;

  elements.result.hidden = true;

  restoreCurrentState();

  clearError();
}

function calculate() {
  saveInputsToState();

  clearError();

  const current = getCurrentState();

  try {
    const payload = {
      totalLand: current.totalLand,
      rows: current.rows,
    };

    const result =
      state.activeMode === "normal"
        ? calculateNormal(payload)
        : calculateGroupLine(payload);

    renderResult(result);

  } catch (error) {
    showError(
      error?.message ||
      "হিসাব করতে সমস্যা হয়েছে। ইনপুটগুলো আবার যাচাই করুন।"
    );
  }
}

function renderResult(result) {
  const unit =
    getCurrentState().landUnit;

  elements.resultRows.innerHTML =
    result.rows.map(
      (row, index) => `
        <article class="hissa-result-row">
          <div class="hissa-result-person">
            <span class="hissa-result-index">
              ${banglaNumber(index + 1)}
            </span>

            <strong>
              ${escapeHtml(row.name)}
            </strong>
          </div>

          <div class="hissa-result-land">
            <strong>
              ${formatLand(row.allocatedLand)}
            </strong>

            <span>
              ${unit}
            </span>
          </div>

          <div class="hissa-result-meta">
            <span>
              Allocation:
              ${formatPercent(row.allocationRatio)}
            </span>

            <span>
              Absolute share:
              ${formatPercent(row.absoluteRatio)}
            </span>
          </div>
        </article>
      `
    ).join("");

  const explanation =
    buildExplanation(result);

  elements.traceList.innerHTML =
    explanation.steps.map(
      (step, index) => `
        <div class="hissa-trace-step">
          <span>${banglaNumber(index + 1)}</span>
          <p>${step}</p>
        </div>
      `
    ).join("");

  elements.traceContent.hidden = true;

  elements.traceToggle
    .setAttribute(
      "aria-expanded",
      "false"
    );

  elements.traceToggle.querySelector(
    "span"
  ).textContent = "+";

  elements.result.hidden = false;

  elements.result.scrollIntoView({
    behavior: "smooth",
    block: "start",
  });
}

function resetCalculator() {
  state[state.activeMode] = {
    totalLand: "",
    landUnit: "শতক",
    rows: [createRow()],
  };

  restoreCurrentState();

  clearError();

  elements.result.hidden = true;
}

elements.modeButtons.forEach(
  (button) => {
    button.addEventListener(
      "click",
      () => {
        setMode(button.dataset.mode);
      }
    );
  }
);

elements.addRow.addEventListener(
  "click",
  () => {
    saveInputsToState();

    getCurrentState()
      .rows
      .push(createRow());

    restoreCurrentState();
  }
);

elements.rows.addEventListener(
  "click",
  (event) => {
    const button =
      event.target.closest(
        "[data-remove-row]"
      );

    if (!button) return;

    saveInputsToState();

    const row =
      button.closest(".hissa-row");

    const id = row.dataset.id;

    const current =
      getCurrentState();

    if (current.rows.length <= 1) {
      return;
    }

    current.rows =
      current.rows.filter(
        (item) => item.id !== id
      );

    restoreCurrentState();
  }
);

elements.calculate.addEventListener(
  "click",
  calculate
);

elements.reset.addEventListener(
  "click",
  resetCalculator
);

elements.rows.addEventListener(
  "input",
  () => {
    saveInputsToState();
  }
);

elements.totalLand.addEventListener(
  "input",
  () => {
    saveInputsToState();
  }
);

elements.landUnit.addEventListener(
  "change",
  () => {
    saveInputsToState();
  }
);

elements.traceToggle.addEventListener(
  "click",
  () => {
    const expanded =
      elements.traceToggle.getAttribute(
        "aria-expanded"
      ) === "true";

    elements.traceToggle.setAttribute(
      "aria-expanded",
      String(!expanded)
    );

    elements.traceContent.hidden =
      expanded;

    elements.traceToggle.querySelector(
      "span"
    ).textContent =
      expanded ? "+" : "−";
  }
);

// Initial state
state.normal.rows = [createRow()];
state.groupline.rows = [createRow()];

restoreCurrentState();
EOF

# --------------------------------------------------
# 4. Scoped Hissa styles
# --------------------------------------------------

cat > src/styles/hissa-calculator.css <<'EOF'
:root {
  --hissa-navy-950: #050a12;
  --hissa-navy-900: #07101c;
  --hissa-navy-850: #0b1625;
  --hissa-navy-800: #101d2d;

  --hissa-cream-50: #faf8f2;
  --hissa-cream-100: #f3efe5;
  --hissa-cream-200: #e8e1d3;

  --hissa-gold-300: #dfc58c;
  --hissa-gold-400: #d4b56e;
  --hissa-gold-500: #c8a45d;
  --hissa-gold-600: #a9823e;

  --hissa-text-dark: #18202b;
  --hissa-text-muted: #68717d;

  --hissa-border-light: rgba(24, 32, 43, 0.12);
  --hissa-border-dark: rgba(255, 255, 255, 0.11);

  --hissa-shadow-soft:
    0 20px 60px rgba(5, 10, 18, 0.08);

  --hissa-radius-sm: 4px;
  --hissa-radius-md: 8px;
  --hissa-radius-lg: 14px;
}

* {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
}

body {
  margin: 0;
  background: var(--hissa-cream-50);
  color: var(--hissa-text-dark);
  font-family:
    "Hind Siliguri",
    system-ui,
    sans-serif;
}

button,
input,
select {
  font: inherit;
}

button {
  cursor: pointer;
}

.hissa-page {
  min-height: 100vh;
}

.hissa-container {
  width: min(
    1180px,
    calc(100% - 40px)
  );

  margin: 0 auto;
}

/* --------------------------------
   Hero
-------------------------------- */

.hissa-hero {
  position: relative;

  padding:
    96px
    0
    84px;

  color: var(--hissa-cream-50);

  background:
    radial-gradient(
      circle at 80% 20%,
      rgba(212, 181, 110, 0.11),
      transparent 34%
    ),
    linear-gradient(
      135deg,
      var(--hissa-navy-950),
      var(--hissa-navy-900)
    );
}

.hissa-kicker,
.hissa-section-kicker {
  margin: 0 0 14px;

  color: var(--hissa-gold-400);

  font-family: Inter, system-ui, sans-serif;
  font-size: 12px;
  font-weight: 700;

  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.hissa-hero h1 {
  max-width: 760px;

  margin: 0;

  font-family:
    "Noto Serif Bengali",
    serif;

  font-size:
    clamp(42px, 6vw, 76px);

  line-height: 1.08;
  letter-spacing: -0.035em;
}

.hissa-hero h1 span {
  color: var(--hissa-gold-400);
}

.hissa-hero-text {
  max-width: 650px;

  margin: 24px 0 0;

  color:
    rgba(244, 241, 232, 0.82);

  font-size: 19px;
  line-height: 1.75;
}

.hissa-hero-note {
  max-width: 700px;

  margin: 18px 0 0;

  color:
    rgba(244, 241, 232, 0.58);

  font-size: 14px;
}

/* --------------------------------
   Workspace
-------------------------------- */

.hissa-workspace {
  padding:
    72px
    0
    110px;
}

.hissa-mode-switch {
  display: flex;

  width: min(
    560px,
    100%
  );

  margin:
    0
    auto
    28px;

  padding: 5px;

  border:
    1px solid
    var(--hissa-border-light);

  border-radius:
    var(--hissa-radius-lg);

  background:
    var(--hissa-cream-100);
}

.hissa-mode-button {
  flex: 1;

  min-height: 48px;

  border: 0;

  border-radius:
    var(--hissa-radius-md);

  background: transparent;

  color:
    var(--hissa-text-muted);

  font-weight: 600;

  transition:
    180ms ease;
}

.hissa-mode-button:hover {
  color:
    var(--hissa-text-dark);
}

.hissa-mode-button.is-active {
  background:
    var(--hissa-navy-900);

  color:
    var(--hissa-cream-50);

  box-shadow:
    0 8px 24px
    rgba(5, 10, 18, 0.12);
}

/* --------------------------------
   Cards
-------------------------------- */

.hissa-card,
.hissa-result {
  width: min(
    900px,
    100%
  );

  margin: 0 auto;

  padding: 34px;

  border:
    1px solid
    var(--hissa-border-light);

  border-radius:
    var(--hissa-radius-lg);

  background: #fff;

  box-shadow:
    var(--hissa-shadow-soft);
}

.hissa-card-header,
.hissa-result-header,
.hissa-share-header {
  display: flex;

  align-items: center;

  justify-content: space-between;

  gap: 24px;
}

.hissa-card-header h2,
.hissa-result-header h2,
.hissa-share-header h3 {
  margin: 0;

  font-family:
    "Noto Serif Bengali",
    serif;

  line-height: 1.25;
}

.hissa-card-header h2 {
  font-size: 28px;
}

.hissa-result-header h2 {
  font-size: 28px;
}

.hissa-share-header {
  margin-top: 48px;
}

.hissa-share-header h3 {
  font-size: 23px;
}

.hissa-mode-badge {
  flex: 0 0 auto;

  padding:
    8px
    12px;

  border:
    1px solid
    rgba(200, 164, 93, 0.35);

  border-radius:
    999px;

  background:
    rgba(200, 164, 93, 0.09);

  color:
    var(--hissa-gold-600);

  font-family: Inter, system-ui, sans-serif;
  font-size: 11px;
  font-weight: 700;

  letter-spacing: 0.08em;
  text-transform: uppercase;
}

/* --------------------------------
   Total land
-------------------------------- */

.hissa-total-land {
  margin-top: 34px;
}

.hissa-total-land label {
  display: block;

  margin-bottom: 9px;

  font-weight: 600;
}

.hissa-land-input {
  display: grid;

  grid-template-columns:
    1fr
    160px;

  gap: 10px;
}

.hissa-land-input input,
.hissa-land-input select,
.hissa-name-field input,
.hissa-unit-field input {
  width: 100%;

  min-height: 48px;

  border:
    1px solid
    var(--hissa-border-light);

  border-radius:
    var(--hissa-radius-md);

  background: #fff;

  color:
    var(--hissa-text-dark);

  outline: none;

  transition:
    border-color 180ms ease,
    box-shadow 180ms ease;
}

.hissa-land-input input,
.hissa-land-input select,
.hissa-name-field input {
  padding:
    0
    14px;
}

.hissa-land-input input:focus,
.hissa-land-input select:focus,
.hissa-name-field input:focus,
.hissa-unit-field input:focus {
  border-color:
    var(--hissa-gold-500);

  box-shadow:
    0 0 0 3px
    rgba(200, 164, 93, 0.12);
}

/* --------------------------------
   Rows
-------------------------------- */

.hissa-rows {
  display: grid;

  gap: 16px;

  margin-top: 18px;
}

.hissa-row {
  padding: 20px;

  border:
    1px solid
    var(--hissa-border-light);

  border-radius:
    var(--hissa-radius-md);

  background:
    var(--hissa-cream-50);
}

.hissa-row-top {
  display: flex;

  align-items: end;

  gap: 14px;
}

.hissa-name-field {
  flex: 1;
}

.hissa-name-field label,
.hissa-unit-field span {
  display: block;

  margin-bottom: 7px;

  color:
    var(--hissa-text-muted);

  font-size: 13px;
  font-weight: 600;
}

.hissa-unit-grid {
  display: grid;

  grid-template-columns:
    repeat(5, 1fr);

  gap: 10px;

  margin-top: 14px;
}

.hissa-unit-field input {
  padding:
    0
    10px;

  text-align: center;
}

.hissa-remove-button {
  width: 44px;
  height: 44px;

  border:
    1px solid
    var(--hissa-border-light);

  border-radius:
    var(--hissa-radius-md);

  background: #fff;

  color:
    var(--hissa-text-muted);

  font-size: 23px;
}

.hissa-remove-button:hover {
  border-color:
    var(--hissa-gold-500);

  color:
    var(--hissa-gold-600);
}

.hissa-add-button {
  min-height: 42px;

  padding:
    0
    16px;

  border:
    1px solid
    rgba(200, 164, 93, 0.45);

  border-radius:
    var(--hissa-radius-md);

  background:
    rgba(200, 164, 93, 0.08);

  color:
    var(--hissa-gold-600);

  font-weight: 700;
}

/* --------------------------------
   Actions
-------------------------------- */

.hissa-actions {
  display: flex;

  gap: 12px;

  margin-top: 28px;
}

.hissa-calculate-button {
  flex: 1;

  min-height: 54px;

  border: 0;

  border-radius:
    var(--hissa-radius-md);

  background:
    var(--hissa-gold-500);

  color:
    var(--hissa-navy-950);

  font-weight: 700;

  box-shadow:
    0 12px 30px
    rgba(200, 164, 93, 0.18);
}

.hissa-calculate-button:hover {
  background:
    var(--hissa-gold-400);
}

.hissa-reset-button {
  min-height: 54px;

  padding:
    0
    22px;

  border:
    1px solid
    var(--hissa-border-light);

  border-radius:
    var(--hissa-radius-md);

  background: #fff;

  color:
    var(--hissa-text-muted);
}

/* --------------------------------
   Error
-------------------------------- */

.hissa-error {
  margin: 18px 0 0;

  padding:
    14px
    16px;

  border:
    1px solid
    rgba(160, 80, 60, 0.22);

  border-radius:
    var(--hissa-radius-md);

  background:
    rgba(160, 80, 60, 0.06);

  color:
    #7d4032;

  font-size: 14px;
}

/* --------------------------------
   Result
-------------------------------- */

.hissa-result {
  margin-top: 28px;
}

.hissa-result-rows {
  display: grid;

  gap: 12px;

  margin-top: 28px;
}

.hissa-result-row {
  display: grid;

  grid-template-columns:
    1.3fr
    1fr;

  gap: 10px;

  padding: 20px;

  border:
    1px solid
    var(--hissa-border-light);

  border-radius:
    var(--hissa-radius-md);

  background:
    var(--hissa-cream-50);
}

.hissa-result-person {
  display: flex;

  align-items: center;

  gap: 12px;
}

.hissa-result-index {
  display: grid;

  width: 32px;
  height: 32px;

  place-items: center;

  border-radius: 50%;

  background:
    var(--hissa-navy-900);

  color:
    var(--hissa-cream-50);

  font-size: 13px;
}

.hissa-result-land {
  display: flex;

  justify-content: flex-end;
  align-items: baseline;

  gap: 6px;
}

.hissa-result-land strong {
  font-family:
    "Noto Serif Bengali",
    serif;

  font-size: 24px;

  color:
    var(--hissa-navy-900);
}

.hissa-result-land span {
  color:
    var(--hissa-text-muted);

  font-size: 13px;
}

.hissa-result-meta {
  grid-column: 1 / -1;

  display: flex;

  gap: 18px;

  color:
    var(--hissa-text-muted);

  font-size: 12px;
}

/* --------------------------------
   Calculation trace
-------------------------------- */

.hissa-trace {
  margin-top: 28px;

  border-top:
    1px solid
    var(--hissa-border-light);
}

.hissa-trace-toggle {
  display: flex;

  width: 100%;

  justify-content: space-between;
  align-items: center;

  min-height: 58px;

  border: 0;

  background: transparent;

  color:
    var(--hissa-text-dark);

  font-weight: 700;

  text-align: left;
}

.hissa-trace-toggle span {
  color:
    var(--hissa-gold-600);

  font-size: 22px;
}

.hissa-trace-content {
  padding:
    4px
    0
    18px;
}

.hissa-trace-step {
  display: flex;

  gap: 12px;

  padding:
    12px
    0;
}

.hissa-trace-step > span {
  display: grid;

  width: 28px;
  height: 28px;

  flex: 0 0 28px;

  place-items: center;

  border-radius: 50%;

  background:
    rgba(200, 164, 93, 0.12);

  color:
    var(--hissa-gold-600);

  font-size: 12px;
  font-weight: 700;
}

.hissa-trace-step p {
  margin: 3px 0 0;

  color:
    var(--hissa-text-muted);

  font-size: 14px;
}

/* --------------------------------
   Disclaimer
-------------------------------- */

.hissa-disclaimer {
  margin-top: 24px;

  padding:
    16px
    18px;

  border:
    1px solid
    rgba(200, 164, 93, 0.25);

  border-radius:
    var(--hissa-radius-md);

  background:
    rgba(200, 164, 93, 0.07);

  color:
    var(--hissa-text-muted);

  font-size: 13px;
  line-height: 1.7;
}

.hissa-disclaimer strong {
  color:
    var(--hissa-text-dark);
}

/* --------------------------------
   Mobile
-------------------------------- */

@media (max-width: 700px) {
  .hissa-container {
    width:
      min(
        100% - 28px,
        1180px
      );
  }

  .hissa-hero {
    padding:
      70px
      0
      60px;
  }

  .hissa-workspace {
    padding:
      48px
      0
      80px;
  }

  .hissa-card,
  .hissa-result {
    padding: 22px;
  }

  .hissa-card-header,
  .hissa-result-header,
  .hissa-share-header {
    align-items: flex-start;

    flex-direction: column;
  }

  .hissa-mode-badge {
    align-self: flex-start;
  }

  .hissa-land-input {
    grid-template-columns: 1fr;
  }

  .hissa-row-top {
    align-items: stretch;
  }

  .hissa-unit-grid {
    grid-template-columns:
      repeat(2, 1fr);
  }

  .hissa-result-row {
    grid-template-columns: 1fr;
  }

  .hissa-result-land {
    justify-content: flex-start;
  }

  .hissa-result-meta {
    flex-direction: column;

    gap: 5px;
  }

  .hissa-actions {
    flex-direction: column;
  }

  .hissa-reset-button {
    width: 100%;
  }
}

@media (max-width: 420px) {
  .hissa-unit-grid {
    grid-template-columns: 1fr;
  }

  .hissa-mode-switch {
    flex-direction: column;
  }
}
EOF

echo ""
echo "=========================================="
echo "Sprint 2 UI created."
echo "=========================================="

echo ""
echo "Created files:"
find \
  src/pages/tools/hissa-calculator.astro \
  src/scripts/hissa-calculator.js \
  src/styles/hissa-calculator.css \
  -type f \
  | sort

echo ""
echo "Next:"
echo "node --test tests/hissa/*.test.js"
echo "npm run build"
echo ""
