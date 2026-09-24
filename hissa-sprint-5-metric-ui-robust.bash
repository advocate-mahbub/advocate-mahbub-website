#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspaces/advocate-mahbub-website"
cd "$ROOT"

STAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKUP_DIR="backups/hissa-sprint-5-metric-ui-robust-$STAMP"
mkdir -p "$BACKUP_DIR"

cp src/pages/tools/hissa-calculator.astro "$BACKUP_DIR/hissa-calculator.astro"
cp src/styles/hissa-calculator.css "$BACKUP_DIR/hissa-calculator.css"
[ -f src/domain/hissa/index.js ] && cp src/domain/hissa/index.js "$BACKUP_DIR/index.js" || true

python3 <<'PY'
from pathlib import Path
import re

ROOT = Path("/workspaces/advocate-mahbub-website")
astro = ROOT / "src/pages/tools/hissa-calculator.astro"
css = ROOT / "src/styles/hissa-calculator.css"
metric = ROOT / "src/domain/hissa/modes/metric.js"
ui = ROOT / "src/scripts/hissa-metric-ui.js"
index = ROOT / "src/domain/hissa/index.js"

a = astro.read_text(encoding="utf-8")
c = css.read_text(encoding="utf-8")

# Independent Metric calculation engine.
metric.parent.mkdir(parents=True, exist_ok=True)
if not metric.exists():
    metric.write_text(r"""
export function calculateMetric({ totalLand, rows }) {
  const land = Number(totalLand);

  if (!Number.isFinite(land) || land < 0) {
    throw new Error("মোট সম্পত্তির পরিমাণ সঠিকভাবে দিন।");
  }

  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error("কমপক্ষে একজন শরিক দিন।");
  }

  const cleanRows = rows.map((row) => ({
    name: String(row?.name ?? "").trim() || "শরিক",
    share: Number(row?.share ?? 0),
  }));

  const totalShare = cleanRows.reduce((sum, row) => sum + row.share, 0);

  if (totalShare > 1000) {
    throw new Error(
      "মোট হিস্যা ১০০০-এর বেশি হয়েছে। কোথাও ইনপুটে ভুল থাকতে পারে। খতিয়ান বা মূল নথির তথ্য আবার যাচাই করুন।"
    );
  }

  if (totalShare === 0) {
    throw new Error("কমপক্ষে একজন শরিকের হিস্যা ০-এর বেশি হতে হবে।");
  }

  return {
    totalShare,
    rows: cleanRows.map((row) => {
      const percentage = (row.share / 1000) * 100;
      const allocatedLand = (land * row.share) / 1000;

      return {
        ...row,
        percentage: percentage.toFixed(4),
        allocatedLand: allocatedLand.toFixed(4),
      };
    }),
    explanation: [
      "Metric Mode-এ City / BS খতিয়ানের ১০০০ ভিত্তিক হিস্যা ব্যবহার করা হয়েছে।",
      `মোট হিস্যা: ${totalShare} / ১০০০।`,
      "প্রতিটি শরিকের হিস্যা = মোট সম্পত্তি × (শরিকের হিস্যা ÷ ১০০০)।",
    ],
  };
}
""", encoding="utf-8")

# Export engine from central index.
idx = index.read_text(encoding="utf-8")
if 'export { calculateMetric } from "./modes/metric.js";' not in idx:
    idx += '\nexport { calculateMetric } from "./modes/metric.js";\n'
    index.write_text(idx, encoding="utf-8")

# Add Metric button without depending on exact whitespace.
if 'data-mode="metric"' not in a:
    m = re.search(
        r'(<button\b[^>]*class="hissa-mode-button"[^>]*data-mode="groupline"[^>]*>.*?</button>)',
        a,
        re.S,
    )
    if not m:
        raise SystemExit("ABORT: GroupLine button could not be located.")
    group = m.group(1)
    metric_button = group.replace('data-mode="groupline"', 'data-mode="metric"', 1)
    metric_button = metric_button.replace("GroupLine Mode", "Metric Mode", 1)
    a = a[:m.end()] + "\n\n" + metric_button + a[m.end():]

# Add Metric panel.
if 'id="hissa-metric-panel"' not in a:
    marker = "<!-- CALCULATOR CARD -->"
    pos = a.find(marker)
    if pos < 0:
        m = re.search(r'<(?:section|div|form)\b[^>]*id="hissa-calculator', a)
        if not m:
            raise SystemExit("ABORT: Calculator insertion point could not be located.")
        pos = m.start()

    panel = """
      <section id="hissa-metric-panel" class="hissa-metric-panel" hidden>
        <div class="hissa-metric-header">
          <span class="hissa-eyebrow">METRIC MODE</span>
          <h2>১০০০ ভিত্তিতে শরিকের হিস্যা দিন</h2>
          <p>City / BS খতিয়ানের জন্য মোট হিস্যা ১০০০-এর ভিত্তিতে দিন।</p>
        </div>

        <div class="hissa-metric-summary">
          <strong>মোট হিস্যা:</strong>
          <span id="hissa-metric-total">০</span>
          <span>/ ১০০০</span>
        </div>

        <div id="hissa-metric-rows" class="hissa-metric-rows"></div>

        <button type="button" id="hissa-metric-add-row" class="hissa-secondary-button">
          + শরিক যোগ করুন
        </button>
      </section>

"""
    a = a[:pos] + panel + a[pos:]

# Separate controller; existing Normal/GroupLine JS remains untouched.
if "hissa-metric-ui.js" not in a:
    tag = '      <script src="/scripts/hissa-metric-ui.js"></script>\n'
    if "</body>" in a:
        a = a.replace("</body>", tag + "    </body>", 1)
    else:
        a += "\n" + tag

astro.write_text(a, encoding="utf-8")

# Metric styling.
if ".hissa-metric-panel" not in c:
    c += """
.hissa-metric-panel {
  margin: 0 0 1.5rem;
  padding: 1.5rem;
  border: 1px solid rgba(198, 157, 78, 0.28);
  border-radius: 18px;
  background: #fbf8f1;
}
.hissa-metric-panel[hidden] { display: none; }
.hissa-metric-summary {
  display: flex;
  gap: .4rem;
  align-items: baseline;
  margin: 1rem 0;
}
.hissa-metric-row {
  display: grid;
  grid-template-columns: 2rem minmax(0,1fr) minmax(120px,.35fr) 42px;
  gap: .7rem;
  align-items: center;
  margin-bottom: .75rem;
}
.hissa-metric-row input {
  min-height: 48px;
  padding: .7rem .85rem;
  border: 1px solid rgba(0,0,0,.12);
  border-radius: 10px;
  background: #fff;
}
.hissa-metric-remove {
  min-height: 42px;
  border: 1px solid rgba(0,0,0,.12);
  border-radius: 10px;
  background: #fff;
}
#hissa-metric-total[data-over-limit="true"] { color: #a33; }
@media (max-width: 640px) {
  .hissa-metric-row { grid-template-columns: 2rem 1fr 42px; }
  .hissa-metric-row input[data-field="share"] { grid-column: 2; }
}
"""
    css.write_text(c, encoding="utf-8")

ui.write_text(r"""
import { calculateMetric } from "../domain/hissa/modes/metric.js";

const BN = "০১২৩৪৫৬৭৮৯";

const en = (value) =>
  String(value ?? "").replace(/[০-৯]/g, (d) => BN.indexOf(d));

const bn = (value) =>
  String(value ?? "").replace(/\d/g, (d) => BN[d]);

const esc = (value) =>
  String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

function initMetric() {
  const button = document.querySelector('[data-mode="metric"]');
  const normal = document.querySelector('[data-mode="normal"]');
  const group = document.querySelector('[data-mode="groupline"]');
  const panel = document.querySelector("#hissa-metric-panel");
  const rowsEl = document.querySelector("#hissa-metric-rows");
  const totalEl = document.querySelector("#hissa-metric-total");
  const add = document.querySelector("#hissa-metric-add-row");
  const totalLand = document.querySelector("#hissa-total-land");
  const calculate = document.querySelector("#hissa-calculate");
  const result = document.querySelector("#hissa-result");
  const resultRows = document.querySelector("#hissa-result-rows");
  const trace = document.querySelector("#hissa-trace-list");

  if (!button || !panel || !rowsEl || !add || !calculate) {
    console.warn("Metric Mode: UI elements not found.");
    return;
  }

  let active = false;
  let rows = [{ id: crypto.randomUUID(), name: "", share: "" }];

  function sync() {
    rows = [...rowsEl.querySelectorAll(".hissa-metric-row")].map((el) => ({
      id: el.dataset.id,
      name: el.querySelector('[data-field="name"]')?.value ?? "",
      share: el.querySelector('[data-field="share"]')?.value ?? "",
    }));
  }

  function updateTotal() {
    const total = rows.reduce((sum, row) => {
      const n = en(row.share).replace(/[^\d]/g, "");
      return sum + (n ? Number(n) : 0);
    }, 0);
    totalEl.textContent = bn(total);
    totalEl.dataset.overLimit = String(total > 1000);
  }

  function render() {
    rowsEl.innerHTML = rows.map((row, i) => `
      <div class="hissa-metric-row" data-id="${row.id}">
        <span>${bn(i + 1)}</span>
        <input type="text" data-field="name" value="${esc(row.name)}" placeholder="নাম লিখুন">
        <input type="text" data-field="share" value="${esc(row.share)}" placeholder="যেমন: ৩০০" inputmode="numeric">
        <button type="button" class="hissa-metric-remove">×</button>
      </div>
    `).join("");
    updateTotal();
  }

  function show() {
    active = true;
    panel.hidden = false;
    document.querySelector("#hissa-rows")?.setAttribute("hidden", "");
    render();
  }

  function hide() {
    active = false;
    panel.hidden = true;
    document.querySelector("#hissa-rows")?.removeAttribute("hidden");
  }

  button.addEventListener("click", (event) => {
    event.stopImmediatePropagation();
    show();
  }, true);

  normal?.addEventListener("click", hide);
  group?.addEventListener("click", hide);

  add.addEventListener("click", () => {
    sync();
    rows.push({ id: crypto.randomUUID(), name: "", share: "" });
    render();
  });

  rowsEl.addEventListener("input", () => {
    sync();
    updateTotal();
  });

  rowsEl.addEventListener("click", (event) => {
    const remove = event.target.closest(".hissa-metric-remove");
    if (!remove) return;
    sync();
    const id = remove.closest(".hissa-metric-row")?.dataset.id;
    rows = rows.length === 1
      ? [{ id: crypto.randomUUID(), name: "", share: "" }]
      : rows.filter((row) => row.id !== id);
    render();
  });

  calculate.addEventListener("click", (event) => {
    if (!active) return;

    event.preventDefault();
    event.stopImmediatePropagation();

    try {
      sync();

      const land = en(totalLand?.value ?? "").trim();

      if (!land || !/^\d+(\.\d+)?$/.test(land)) {
        throw new Error(
          "উপরে মোট জমির পরিমাণ বসানো হয়নি। পরিমাণ বসিয়ে নিচের “হিসাব করুন” বাটনে আবার চাপুন।"
        );
      }

      const clean = rows.map((row) => {
        const raw = en(row.share).trim();

        if (!/^\d+$/.test(raw)) {
          throw new Error(
            "হিস্যার ঘরে শুধু সংখ্যা দিন। Unicode বাংলা সংখ্যা ও English সংখ্যা দুটোই গ্রহণযোগ্য।"
          );
        }

        return {
          name: row.name.trim() || "শরিক",
          share: Number(raw),
        };
      });

      const totalShare = clean.reduce((sum, row) => sum + row.share, 0);

      if (totalShare > 1000) {
        throw new Error(
          "মোট হিস্যা ১০০০-এর বেশি হয়েছে। কোথাও তথ্য বসাতে ভুল হতে পারে। অনেক সময় খতিয়ানের তথ্যের মধ্যেও ভুল থাকে। মূল খতিয়ান/নথি আবার যাচাই করুন।"
        );
      }

      const data = calculateMetric({
        totalLand: Number(land),
        rows: clean,
      });

      if (result) result.hidden = false;

      if (resultRows) {
        resultRows.innerHTML = data.rows.map((row, i) => `
          <article class="hissa-result-row">
            <div class="hissa-result-person">
              <span class="hissa-result-index">${bn(i + 1)}</span>
              <strong>${esc(row.name)}</strong>
            </div>
            <div class="hissa-result-land">
              <strong>${row.allocatedLand}</strong>
              <span>শতক</span>
            </div>
            <div class="hissa-result-meta">
              <span>হিস্যার অংশ: ${row.percentage}%</span>
              <span>শেয়ার: ${bn(row.share)} / ১০০০</span>
            </div>
          </article>
        `).join("");
      }

      if (trace) {
        trace.innerHTML = data.explanation
          .map((item) => `<li>${esc(item)}</li>`)
          .join("");
      }
    } catch (error) {
      const errorEl = document.querySelector("#hissa-error");

      if (errorEl) {
        errorEl.textContent = error?.message || "ইনপুটগুলো আবার যাচাই করুন।";
        errorEl.hidden = false;
      } else {
        window.alert(error?.message || "ইনপুটগুলো আবার যাচাই করুন।");
      }
    }
  }, true);

  render();
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initMetric, { once: true });
} else {
  initMetric();
}
""", encoding="utf-8")

print("Metric Mode patch completed.")
PY

echo
echo "=== Hissa tests ==="
node --test tests/hissa/*.test.js

echo
echo "=== Production build ==="
npm run build

echo
echo "SUCCESS"
echo "Backup: $BACKUP_DIR"
echo "Refresh the calculator and check the new Metric Mode tab."
