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
        <label>শরীক / Group</label>

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
        aria-label="এই শরীক বাদ দিন"
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

    const validatedRows = validateCurrentRows(payload.rows);

    const validatedPayload = {
      ...payload,
      rows: validatedRows,
    };

    const result =
      state.activeMode === "normal"
        ? calculateNormal(validatedPayload)
        : calculateGroupLine(validatedPayload);

    renderResult(result);

  } catch (error) {
    showError(
      error?.message ||
      "হিসাব করতে সমস্যা হয়েছে। ইনপুটগুলো আবার যাচাই করুন।"
    );
  }
}

function renderResult(result) {
  const unit = getCurrentState().landUnit || "শতক";

  const noteHtml = result.totalShareNote
    ? `<div class="hissa-mode-note" role="note">${escapeHtml(result.totalShareNote)}</div>`
    : "";

  elements.resultRows.innerHTML =
    noteHtml +
    result.rows
    .map((row, index) => {
      const sourceRow = getCurrentState().rows[index] || {};
      const hissa = formatInputHissa(sourceRow);

      return `
        <article class="hissa-result-row">
          <div class="hissa-result-person">
            <span class="hissa-result-index">${banglaNumber(index + 1)}</span>
            <strong>${escapeHtml(
              row.name || sourceRow.name || `শরীক ${banglaNumber(index + 1)}`
            )}</strong>
          </div>

          <div class="hissa-result-land">
            <strong>${formatLand(row.allocatedLand)}</strong>
            <span>${escapeHtml(unit)}</span>
          </div>

          <div class="hissa-result-meta">
            <span>
              হিস্যার অংশ:
              <strong>${escapeHtml(hissa.symbol)}</strong>
            </span>

            <small>(${escapeHtml(hissa.text)})</small>

            <span>
              দশমিকে অংশ:
              ${formatPercent(row.absoluteRatio)}
            </span>
          </div>
        </article>
      `;
    })
    .join("");

  elements.result.hidden = false;

  if (elements.traceList) {
    elements.traceList.innerHTML = buildBanglaTrace(result);
  }
}

function normalizeIntegerInput(value) {
  const raw = String(value ?? "").trim();
  if (!raw) return null;

  const normalized = raw
    .replace(/[০-৯]/g, (d) => "০১২৩৪৫৬৭৮৯".indexOf(d))
    .replace(/[٬,]/g, "");

  if (!/^\d+$/.test(normalized)) return null;
  return Number(normalized);
}

const HissaLimits = Object.freeze({
  anna: { min: 0, max: 15, label: "আনা" },
  gonda: { min: 0, max: 19, label: "গন্ডা" },
  kora: { min: 0, max: 3, label: "কড়া" },
  kranti: { min: 0, max: 2, label: "ক্রান্তি" },
  til: { min: 0, max: 19, label: "তিল" },
});

function validateHissaField(value, key) {
  const limit = HissaLimits[key];
  if (!limit) return null;

  const raw = String(value ?? "").trim();
  if (!raw) return 0;

  const number = normalizeIntegerInput(raw);

  if (number === null) {
    throw new Error(`${limit.label}-এ শুধু ০–৯ পর্যন্ত সংখ্যা ব্যবহার করুন।`);
  }

  if (number < limit.min || number > limit.max) {
    throw new Error(
      `${limit.label}-এর মান ${limit.min} থেকে ${limit.max}-এর মধ্যে হতে হবে।`
    );
  }

  return number;
}

function validateCurrentRows(rows) {
  return rows.map((row, index) => ({
    ...row,
    name: String(row.name ?? "").trim(),
    anna: validateHissaField(row.anna, "anna"),
    gonda: validateHissaField(row.gonda, "gonda"),
    kora: validateHissaField(row.kora, "kora"),
    kranti: validateHissaField(row.kranti, "kranti"),
    til: validateHissaField(row.til, "til"),
    __index: index,
  }));
}

const ANNA_SYMBOLS = Object.freeze({
  0: "",
  1: "⁄",
  2: "৵",
  3: "৶",
  4: "৷",
  5: "৷⁄",
  6: "৷৵",
  7: "৷৶",
  8: "৷৷",
  9: "৷৷⁄",
  10: "৷৷৵",
  11: "৷৷৶",
  12: "৸",
  13: "৸⁄",
  14: "৸৵",
  15: "৸৶",
  16: "১",
});

const KORA_SYMBOLS = Object.freeze({
  0: "",
  1: "৷",
  2: "৷৷",
  3: "৸",
});

const KRANTI_SYMBOLS = Object.freeze({
  0: "",
  1: "৴",
  2: "৴৴",
});

function formatInputHissa(row) {
  const anna = normalizeIntegerInput(row.anna) ?? 0;
  const gonda = normalizeIntegerInput(row.gonda) ?? 0;
  const kora = normalizeIntegerInput(row.kora) ?? 0;
  const kranti = normalizeIntegerInput(row.kranti) ?? 0;
  const til = normalizeIntegerInput(row.til) ?? 0;

  const symbol =
    `${ANNA_SYMBOLS[anna] ?? ""}` +
    `${gonda ? banglaNumber(gonda) : ""}` +
    `${KORA_SYMBOLS[kora] ?? ""}` +
    `${KRANTI_SYMBOLS[kranti] ?? ""}` +
    `${til ? banglaNumber(til) : ""}`;

  return {
    symbol: symbol || "০",
    text:
      `${banglaNumber(anna)} আনা ` +
      `${banglaNumber(gonda)} গন্ডা ` +
      `${banglaNumber(kora)} কড়া ` +
      `${banglaNumber(kranti)} ক্রান্তি ` +
      `${banglaNumber(til)} তিল`,
  };
}

function buildBanglaTrace(result) {
  const rows = result.rows || [];
  const stateNow = getCurrentState();
  const unit = stateNow.landUnit || "শতক";

  const items = [
    "প্রতিটি শরীকের হিস্যাংশ তিলে কনভার্ট করে হিসাব করা হয়েছে।",
    `মোট শেয়ার: ${formatTraceNumber(result.totalListedShare ?? 0)} তিল-ভিত্তিক একক।`,
    `মোট ${formatLand(result.totalLand ?? stateNow.totalLand)} ${unit} জমি শরীকদের হিস্যার অনুপাতে বণ্টন করা হয়েছে।`,
  ];

  rows.forEach((row, index) => {
    items.push(
      `${banglaNumber(index + 1)} নম্বর শরীকের হিস্যা অনুযায়ী ` +
      `${formatLand(row.allocatedLand)} ${unit} নির্ধারণ করা হয়েছে।`
    );
  });

  return items.map((item) => `<li>${escapeHtml(item)}</li>`).join("");
}

function formatTraceNumber(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return "০";
  return banglaNumber(n.toLocaleString("en-US"));
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
