#!/usr/bin/env bash
# Deploy openefb landing page to Cloudflare Pages
# First run: ensure you've logged in once with `wrangler login`
# and that the Pages project "openefb" exists (created automatically on first deploy).
set -euo pipefail

cd "$(dirname "$0")"

# Sanity check: required files
for f in index.html pretext.js variant-A-paper-day.webp variant-B-dark-dusk.webp variant-C-red-night.webp _headers wrangler.jsonc; do
  [ -f "$f" ] || { echo "MISSING: $f" >&2; exit 1; }
done

# Deploy to production (--branch=main maps to the production environment by default)
wrangler pages deploy . \
  --project-name=openefb \
  --branch=main \
  --commit-dirty=true
