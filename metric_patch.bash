#!/usr/bin/env bash
set -euo pipefail

PAGE="src/pages/tools/hissa-calculator.astro"
UI="src/scripts/hissa-metric-ui.js"
STAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKUP="backups/hissa-metric-function-${STAMP}"

[[ -f "$PAGE" ]] || { echo "ABORT: $PAGE not found."; exit 1; }
mkdir -p "$BACKUP"
cp "$PAGE" "$BACKUP/hissa-calculator.astro"
[[ -f "$UI" ]] && cp "$UI" "$BACKUP/hissa-metric-ui.js"

cat > "$UI" <<'JS'
/*
 * Hissa Calculator — Metric Mode UI/engine bridge
 * Metric Mode uses a separate 1000-point share system.
 * It does not alter Normal/GroupLine calculation engines.
 */
(() => {
  "use strict";

  const $ = (s, root = document) => root.querySelector(s);
  const $$ = (s, root = document) => [...root.querySelectorAll(s)];

  const DIGITS = new Map([
    ["০","0"],["১","1"],["২","2"],["৩","3"],["৪","4"],
    ["৫","5"],["৬","6"],["৭","7"],["৮","8"],["৯","9"],
    ["٠","0"],["١","1"],["٢","2"],["٣","3"],["٤","4"],
    ["٥","5"],["٦","6"],["٧","7"],["٨","8"],["٩","9"],
    ["۰","0"],["۱","1"],["۲","2"],["۳","3"],["۴","4"],
    ["۵","5"],["۶","6"],["۷","7"],["۸","8"],["۹","9"]
  ]);

  const normalizeDigits = (value) =>
    String(value ?? "").replace(/[\u09E6-\u09EF\u0660-\u0669\u06F0-\u06F9]/g, ch => DIGITS.get(ch) ?? ch);

  const bn = value =>
    String(value).replace(/\d/g, d => "০১২৩৪৫৬৭৮৯"[d]);

  const parseInteger = value => {
    const normalized = normalizeDigits(value).trim().replace(/[,\s]/g, "");
    if (!/^\d+$/.test(normalized)) return null;
    const n = Number(normalized);
    return Number.isSafeInteger(n) ? n : null;
  };

  const modeButtons = () => $$(".hissa-mode-button");
  const metricButton = () => $('.hissa-mode-button[data-mode="metric"]');

  let active = false;
  let metricRows = [];

  function getEls() {
    return {
      card: $("#hissa-calculator"),
      total: $("#hissa-total-land"),
      unit: $("#hissa-land-unit"),
      rows: $("#hissa-rows"),
      calculate: $("#hissa-calculate"),
      result: $("#hissa-result"),
      resultRows: $("#hissa-result-rows"),
      error: $("#hissa-error")
    };
  }

  function setError(message) {
    const el = getEls().error;
    if (!el) {
      window.alert(message);
      return;
    }
    el.textContent = message;
    el.hidden = false;
    el.setAttribute("role", "alert");
  }

  function clearError() {
    const el = getEls().error;
    if (el) {
      el.textContent = "";
      el.hidden = true;
    }
  }

  function metricTemplate(index, row = {}) {
    return `
      <div class="hissa-row metric-share-row" data-metric-row="${index}">
        <div class="metric-row-head">
          <label>
            শরিক / Group
            <input data-metric-field="name" type="text"
              value="${escapeHtml(row.name || "")}"
              placeholder="নাম লিখুন">
          </label>
          <button type="button" class="metric-remove-row" aria-label="শরিক বাদ দিন">×</button>
        </div>
        <label class="metric-share-field">
          <span>হিস্যা</span>
          <input data-metric-field="share" type="text"
            inputmode="numeric"
            autocomplete="off"
            value="${escapeHtml(row.share ?? "")}"
            placeholder="যেমন: ৩০০ বা 300">
          <small>০–১০০০</small>
        </label>
      </div>`;
  }

  function escapeHtml(value) {
    return String(value ?? "")
      .replace(/&/g, "&amp;").replace(/</g, "&lt;")
      .replace(/>/g, "&gt;").replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function ensureRows() {
    if (!metricRows.length) metricRows = [{ name: "", share: "" }];
  }

  function renderMetricRows() {
    const { rows } = getEls();
    if (!rows) return;
    ensureRows();
    rows.innerHTML = metricRows.map(metricTemplate).join("");

    $$(".metric-remove-row", rows).forEach((button, index) => {
      button.addEventListener("click", () => {
        if (metricRows.length === 1) {
          metricRows[0] = { name: "", share: "" };
        } else {
          metricRows.splice(index, 1);
        }
        renderMetricRows();
      });
    });

    $$('[data-metric-field]', rows).forEach(input => {
      input.addEventListener("input", () => {
        const rowEl = input.closest("[data-metric-row]");
        const i = Number(rowEl?.dataset.metricRow);
        if (!Number.isInteger(i)) return;
        const field = input.dataset.metricField;
        metricRows[i][field] = input.value;
      });
    });
  }

  function setMetricInputMode() {
    const { total, unit } = getEls();
    if (total) {
      total.type = "text";
      total.inputMode = "decimal";
      total.placeholder = "যেমন: ১০ বা 10";
    }
    if (unit) {
      unit.value = unit.options?.length ? [...unit.options].find(o =>
        /শতক|decimal|shotok/i.test(o.textContent || "")
      )?.value || unit.value : unit.value;
    }
  }

  function enterMetricMode() {
    active = true;
    clearError();
    ensureRows();

    modeButtons().forEach(b => {
      const isMetric = b === metricButton();
      b.classList.toggle("is-active", isMetric);
      b.setAttribute("aria-selected", String(isMetric));
    });

    const card = getEls().card;
    if (card) card.dataset.activeMode = "metric";

    setMetricInputMode();
    renderMetricRows();

    const badge = document.querySelector(".hissa-mode-badge, [data-active-mode]");
    if (badge && !badge.matches('[data-active-mode]')) badge.textContent = "METRIC MODE";

    // The existing page script must not be allowed to submit Anna/Gonda/etc.
    // Metric calculation is handled here.
  }

  function leaveMetricMode() {
    active = false;
    const current = getEls();
    modeButtons().forEach(b => {
      const isActive = b.classList.contains("is-active");
      b.setAttribute("aria-selected", String(isActive));
    });
  }

  function calculateMetric() {
    if (!active) return false;
    clearError();

    const { total, result, resultRows } = getEls();
    const totalLand = Number(normalizeDigits(total?.value).replace(/,/g, ""));
    if (!Number.isFinite(totalLand) || totalLand <= 0) {
      setError("মোট জমির পরিমাণ বসানো হয়নি। পরিমাণ বসিয়ে নিচের “হিসাব করুন” বাটনে আবার চাপুন।");
      return true;
    }

    const parsed = metricRows.map((row, index) => {
      const share = parseInteger(row.share);
      return { ...row, index, share };
    });

    if (parsed.some(r => r.share === null || r.share < 0)) {
      setError("প্রতিটি শরিকের হিস্যা ০ থেকে ১০০০-এর মধ্যে একটি পূর্ণসংখ্যা হতে হবে। বাংলা, English বা Unicode digit ব্যবহার করা যাবে।");
      return true;
    }

    const totalShare = parsed.reduce((sum, r) => sum + r.share, 0);

    if (totalShare > 1000) {
      setError(`মোট হিস্যা ${bn(totalShare)}। Metric Mode-এ মোট হিস্যা ১০০০-এর বেশি হতে পারে না। কোথাও ইনপুটে ভুল হয়েছে কি না, অথবা মূল খতিয়ানের হিস্যায় ভুল আছে কি না, অনুগ্রহ করে যাচাই করুন।`);
      if (result) result.hidden = true;
      return true;
    }

    if (totalShare === 0) {
      setError("কমপক্ষে একজন শরিকের হিস্যা দিতে হবে।");
      if (result) result.hidden = true;
      return true;
    }

    const unit = getEls().unit?.value || "শতক";
    const rows = parsed.map((r, i) => {
      const ratio = r.share / 1000;
      return {
        name: r.name?.trim() || `শরিক ${bn(i + 1)}`,
        share: r.share,
        ratio,
        land: totalLand * ratio
      };
    });

    if (resultRows) {
      resultRows.innerHTML = rows.map(r => `
        <article class="hissa-result-row">
          <div class="hissa-result-person">
            <span class="hissa-result-index">${bn(rows.indexOf(r) + 1)}</span>
            <strong>${escapeHtml(r.name)}</strong>
          </div>
          <div class="hissa-result-land">
            <strong>${r.land.toFixed(4)}</strong>
            <span>${escapeHtml(unit)}</span>
          </div>
          <div class="hissa-result-meta">
            <span>হিস্যার অংশ: ${bn(r.share)}/১০০০</span>
            <span>দশমিকে অংশ: ${(r.ratio * 100).toFixed(4)}%</span>
          </div>
        </article>
      `).join("");
    }

    if (result) result.hidden = false;
    return true;
  }

  function bind() {
    const metric = metricButton();
    if (!metric) return;

    metric.addEventListener("click", e => {
      e.preventDefault();
      e.stopImmediatePropagation();
      enterMetricMode();
    }, true);

    modeButtons().forEach(button => {
      if (button === metric) return;
      button.addEventListener("click", () => {
        leaveMetricMode();
      }, true);
    });

    const { calculate } = getEls();
    if (calculate) {
      calculate.addEventListener("click", e => {
        if (!active) return;
        e.preventDefault();
        e.stopImmediatePropagation();
        calculateMetric();
      }, true);
    }

    document.addEventListener("click", e => {
      const add = e.target.closest("#hissa-add-row");
      if (!active || !add) return;
      e.preventDefault();
      e.stopImmediatePropagation();
      metricRows.push({ name: "", share: "" });
      renderMetricRows();
    }, true);

    // If page restored Metric Mode via state/data, initialize it.
    if (metric.classList.contains("is-active") || document.body.dataset.activeMode === "metric") {
      enterMetricMode();
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", bind, { once: true });
  } else {
    bind();
  }
})();
JS

echo "Metric UI engine replaced: $UI"

echo
echo "Running tests..."
node --test tests/hissa/*.test.js

echo
echo "Running production build..."
npm run build

echo
echo "SUCCESS"
echo "Metric Mode function patch installed."
echo "Backup: $BACKUP"
echo
echo "Next browser tests:"
echo "1) Click Metric Mode"
echo "2) Enter total land = 10"
echo "3) Karim = 300, Rahim = 300, Jalil = 400"
echo "4) Test Bengali digits: ৩০০, ৩০০, ৪০০"
echo "5) Test 1001 total: calculation must stop with notification"
