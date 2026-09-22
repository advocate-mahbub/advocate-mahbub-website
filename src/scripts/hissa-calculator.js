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
              হিস্যার অংশ:
              ${formatPercent(row.allocationRatio)}
            </span>

            <span>
              দশমিকে অংশ:
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
