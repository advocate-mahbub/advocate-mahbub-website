#!/usr/bin/env bash

set -e

PROJECT_ROOT="/workspaces/advocate-mahbub-website"
PAGE="$PROJECT_ROOT/src/pages/legal-knowledge/[slug].astro"
CSS="$PROJECT_ROOT/src/styles/legal-knowledge.css"

cd "$PROJECT_ROOT"

if [ ! -f "$PAGE" ]; then
  echo "ERROR: Category page not found."
  exit 1
fi

if [ ! -f "$CSS" ]; then
  echo "ERROR: Legal Knowledge CSS not found."
  exit 1
fi

python3 - <<'PY'
from pathlib import Path

page = Path("src/pages/legal-knowledge/[slug].astro")
text = page.read_text(encoding="utf-8")

marker = """          <section class="knowledge-consultation">

            <p class="knowledge-eyebrow">
              KNOWLEDGE HUB
            </p>
"""

if "knowledge-featured-article" in text:
    print("OK: Featured Property article already exists.")
else:
    if marker not in text:
        raise SystemExit(
            "ERROR: Knowledge Hub section was not found. "
            "No changes were made."
        )

    featured = """          {category.slug === 'property-land' && (
            <section class="knowledge-featured-article">

              <div class="knowledge-featured-copy">

                <p class="knowledge-eyebrow">
                  FEATURED KNOWLEDGE
                </p>

                <h2>
                  জমি কেনার আগে মালিকানা কীভাবে যাচাই করবেন?
                </h2>

                <p>
                  জমি কেনার আগে শুধু seller-এর কথা বা একটি document দেখে
                  সিদ্ধান্ত নেওয়া যথেষ্ট নয়। Ownership chain, দলিল,
                  খতিয়ান, নামজারি, দখল এবং সম্ভাব্য dispute—কোন বিষয়গুলো
                  আগে যাচাই করবেন, তা এই practical guide-এ ধাপে ধাপে দেখুন।
                </p>

                <div class="knowledge-featured-meta">
                  <span>PROPERTY DUE DILIGENCE</span>
                  <span>10 গুরুত্বপূর্ণ বিষয়</span>
                </div>

              </div>

              <a
                href="/legal-knowledge/property-land/jomi-kenar-age-malikana-jachai/"
                class="knowledge-primary-cta"
              >
                পুরো article পড়ুন
                <span aria-hidden="true">→</span>
              </a>

            </section>
          )}

"""

    text = text.replace(
        marker,
        featured + marker,
        1
    )

    page.write_text(text, encoding="utf-8")

    print("OK: Property & Land featured article added.")

PY

python3 - <<'PY'
from pathlib import Path

css_file = Path("src/styles/legal-knowledge.css")
css = css_file.read_text(encoding="utf-8")

if ".knowledge-featured-article" in css:
    print("OK: Featured article CSS already exists.")
else:
    css += r'''

/* =========================================
   FEATURED ARTICLE — PROPERTY & LAND
   ========================================= */

.knowledge-featured-article {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 50px;
  margin-top: 70px;
  padding: 50px;
  background: #fffdf8;
  border: 1px solid #e4dccd;
}

.knowledge-featured-copy {
  max-width: 820px;
}

.knowledge-featured-copy h2 {
  max-width: 760px;
}

.knowledge-featured-copy > p:not(.knowledge-eyebrow) {
  max-width: 760px;
  margin: 20px 0 0;
  color: #596273;
  line-height: 1.8;
}

.knowledge-featured-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 12px 24px;
  margin-top: 22px;
  color: #8c6c32;
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.08em;
}

.knowledge-featured-meta span {
  display: inline-block;
}

.knowledge-featured-article .knowledge-primary-cta {
  flex-shrink: 0;
}

@media (max-width: 900px) {
  .knowledge-featured-article {
    align-items: flex-start;
    flex-direction: column;
    gap: 28px;
    padding: 40px;
  }
}

@media (max-width: 600px) {
  .knowledge-featured-article {
    margin-top: 50px;
    padding: 28px 22px;
  }

  .knowledge-featured-meta {
    flex-direction: column;
    gap: 8px;
  }
}
'''

    css_file.write_text(css.rstrip() + "\n", encoding="utf-8")

    print("OK: Featured article CSS added.")

PY

echo
echo "=========================================="
echo "PROPERTY & LAND CATEGORY UPDATED"
echo "=========================================="
echo

echo "Checking Astro:"
grep -n -A45 "knowledge-featured-article" \
  "$PAGE" | head -55

echo
echo "Running production build..."
echo

npm run build

echo
echo "=========================================="
echo "BUILD SUCCESSFUL"
echo "=========================================="
