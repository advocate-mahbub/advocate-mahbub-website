#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

TARGET="src/pages/legal-clarity.astro"
BACKUP_DIR="backups/legal-clarity"
TIMESTAMP="$(date +%Y-%m-%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"

if [[ -f "$TARGET" ]]; then
  cp "$TARGET" "$BACKUP_DIR/legal-clarity.$TIMESTAMP.astro"
  echo "Backup created: $BACKUP_DIR/legal-clarity.$TIMESTAMP.astro"
fi

echo "Running diff check..."
git diff --check

echo "Running production build..."
npm run build

echo
echo "Build passed."
echo "No commit or push was performed."
echo
echo "Review with:"
echo "  git status --short"
echo "  git diff -- src/pages/legal-clarity.astro"
