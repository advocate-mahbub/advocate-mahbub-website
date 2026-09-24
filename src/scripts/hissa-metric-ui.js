const root = document;

const metricState = {
  rows: [{ id: crypto.randomUUID(), name: "", share: "" }],
};

const DIGITS = new Map([
  ["০","0"],["১","1"],["২","2"],["৩","3"],["৪","4"],
  ["৫","5"],["৬","6"],["৭","7"],["৮","8"],["৯","9"],
  ["٠","0"],["١","1"],["٢","2"],["٣","3"],["٤","4"],
  ["٥","5"],["٦","6"],["٧","7"],["٨","8"],["٩","9"],
]);

function normalizeDigits(value) {
  return String(value ?? "").replace(/[০-৯٠-٩]/g, d => DIGITS.get(d) ?? d);
}

function toNumber(value) {
  const normalized = normalizeDigits(value).replace(/[,\s]/g, "");
  if (!/^\d+$/.test(normalized)) return NaN;
  return Number(normalized);
}

function banglaNumber(value) {
  return String(value).replace(/\d/g, d => "০১২৩৪৫৬৭৮৯"[d]);
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function getElements() {
  return {
    buttons: [...document.querySelectorAll(".hissa-mode-button")],
    total: document.querySelector("#hissa-total-land"),
    unit: document.querySelector("#hissa-land-unit"),
    rows: document.querySelector("#hissa-rows"),
    add: document.querySelector("#hissa-add-row"),
    calculate: document.querySelector("#hissa-calculate"),
    result: document.querySelector("#hissa-result"),
    resultRows: document.querySelector("#hissa-result-rows"),
    error: document.querySelector("#hissa-error"),
  };
}

function metricActive() {
  return Boolean(
    document.querySelector(
      '.hissa-mode-button[data-mode="metric"].is-active'
    )
  );
}

function showMetricError(message) {
  const e = getElements();

  if (!e.error) {
    window.alert(message);
    return;
  }

  e.error.textContent = message;
  e.error.hidden = false;
  e.error.setAttribute("role", "alert");
}

function clearMetricError() {
  const e = getElements();
  if (e.error) e.error.hidden = true;
}

function renderMetricRows() {
  const e = getElements();
  if (!e.rows) return;

  e.rows.innerHTML = metricState.rows.map((row, index) => `
    <div class="hissa-row metric-row" data-metric-id="${row.id}">
      <div class="metric-row-head">
        <label>শরীক ${banglaNumber(index + 1)}</label>
        <button type="button" class="metric-remove"
          data-metric-remove="${row.id}"
          aria-label="শরীক বাদ দিন">×</button>
      </div>

      <div class="metric-fields">
        <input class="metric-name"
          data-metric-name="${row.id}"
          type="text"
          value="${escapeHtml(row.name)}"
          placeholder="নাম লিখুন"
          autocomplete="off">

        <input class="metric-share"
          data-metric-share="${row.id}"
          type="text"
          value="${escapeHtml(row.share)}"
          inputmode="numeric"
          pattern="[0-9০-৯٠-٩]*"
          placeholder="হিস্যা (০–১০০০)"
          autocomplete="off">
      </div>
    </div>
  `).join("");
}

function activateMetric() {
  const e = getElements();

  e.buttons.forEach(button => {
    const active = button.dataset.mode === "metric";
    button.classList.toggle("is-active", active);
    button.setAttribute("aria-selected", String(active));
  });

  document
    .querySelectorAll(".hissa-mode-badge")
    .forEach((badge) => {
      badge.textContent = "METRIC MODE";
    });

  renderMetricRows();
  clearMetricError();
}

function calculateMetric() {
  const e = getElements();
  clearMetricError();

  const land = toNumber(e.total?.value);

  if (!Number.isFinite(land) || land < 0) {
    showMetricError("মোট জমির পরিমাণ সঠিকভাবে দিন।");
    return;
  }

  let total = 0;
  const rows = [];

  for (let i = 0; i < metricState.rows.length; i++) {
    const row = metricState.rows[i];
    const share = toNumber(row.share);

    if (!Number.isFinite(share) || share < 0) {
      showMetricError(
        `শরীক ${banglaNumber(i + 1)}-এর হিস্যা সঠিকভাবে দিন।`
      );
      return;
    }

    total += share;

    rows.push({
      name: row.name.trim() || `শরীক ${banglaNumber(i + 1)}`,
      share,
    });
  }

  const totalWarning =
    total < 1000
      ? "সতর্কতা: প্রদত্ত মোট হিস্যা ১০০০-এর কম। হিসাব দেওয়া হয়েছে, তবে খতিয়ানের সম্পূর্ণ হিস্যা দেওয়া হয়েছে কি না যাচাই করুন।"
      : total > 1000
        ? "সতর্কতা: প্রদত্ত মোট হিস্যা ১০০০-এর বেশি। হিসাব দেওয়া হয়েছে, তবে ইনপুটের হিস্যা ও খতিয়ানের তথ্য ভালোভাবে যাচাই করুন।"
        : "";

  if (total === 0) {
    showMetricError("অন্তত একজন শরীকের হিস্যা দিতে হবে।");
    return;
  }

  if (!e.resultRows) return;

  const warningHtml = totalWarning
    ? `<div class="hissa-mode-warning" role="alert">${escapeHtml(totalWarning)}</div>`
    : "";

  e.resultRows.innerHTML =
    warningHtml +
    rows.map(row => {
    const allocationRatio = row.share / total;
    const absoluteRatio = row.share / 1000;
    const allocatedLand = land * allocationRatio;

    return `
      <article class="hissa-result-row">
        <div class="hissa-result-person">
          <strong>${escapeHtml(row.name)}</strong>
        </div>

        <div class="hissa-result-land">
          <strong>${allocatedLand.toFixed(4)}</strong>
          <span>${escapeHtml(e.unit?.value || "শতক")}</span>
        </div>

        <div class="hissa-result-meta">
          <span>হিস্যার অংশ: ${row.share}/1000</span>
          <span>দশমিকে অংশ: ${(absoluteRatio * 100).toFixed(4)}%</span>
        </div>
      </article>
    `;
  }).join("");

  document
    .querySelectorAll(".hissa-mode-badge")
    .forEach((badge) => {
      badge.textContent = "METRIC MODE";
    });

  if (e.result) e.result.hidden = false;
}

function bindMetricMode() {
  const e = getElements();

  e.buttons.forEach(button => {
    button.addEventListener("click", event => {
      if (button.dataset.mode !== "metric") return;

      event.preventDefault();
      event.stopImmediatePropagation();

      activateMetric();
    }, true);
  });

  e.add?.addEventListener("click", event => {
    if (!metricActive()) return;

    event.preventDefault();
    event.stopImmediatePropagation();

    metricState.rows.push({
      id: crypto.randomUUID(),
      name: "",
      share: "",
    });

    renderMetricRows();
  }, true);

  e.rows?.addEventListener("input", event => {
    if (!metricActive()) return;

    const target = event.target;
    const id =
      target.dataset.metricName ||
      target.dataset.metricShare;

    if (!id) return;

    const row = metricState.rows.find(item => item.id === id);
    if (!row) return;

    if (target.dataset.metricName) {
      row.name = target.value;
    }

    if (target.dataset.metricShare) {
      row.share = normalizeDigits(target.value);
      target.value = row.share;
    }
  }, true);

  e.rows?.addEventListener("click", event => {
    if (!metricActive()) return;

    const id = event.target.dataset.metricRemove;
    if (!id) return;

    event.preventDefault();
    event.stopImmediatePropagation();

    metricState.rows =
      metricState.rows.filter(row => row.id !== id);

    if (!metricState.rows.length) {
      metricState.rows.push({
        id: crypto.randomUUID(),
        name: "",
        share: "",
      });
    }

    renderMetricRows();
  }, true);

  e.calculate?.addEventListener("click", event => {
    if (!metricActive()) return;

    event.preventDefault();
    event.stopImmediatePropagation();

    calculateMetric();
  }, true);
}

if (document.readyState === "loading") {
  document.addEventListener(
    "DOMContentLoaded",
    bindMetricMode,
    { once: true }
  );
} else {
  bindMetricMode();
}
