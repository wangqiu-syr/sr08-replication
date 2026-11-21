#!/usr/bin/env bash
# Build report/report.pdf from report/report.md: pandoc writes a standalone
# HTML page (figures embedded), and Chromium (Playwright) prints it.
# Needs pandoc >= 3 and Node with Playwright. Run from anywhere:
#   bash report/pdf/build.sh
# REF sets the GitHub ref that the report's relative links point to
# (default: the version in CITATION.cff, as a tag, e.g. v0.1.0).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
version=$(sed -n 's/^version: *"\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' "$root/CITATION.cff")
repo=$(sed -n 's|^repository-code: *"\{0,1\}https://github.com/\([^"]*\)"\{0,1\}$|\1|p' "$root/CITATION.cff")
ref=${REF:-v$version}
title=$(sed -n '1s/^# //p' "$root/report/report.md")
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

cd "$root/report"
REPO_BLOB="https://github.com/$repo/blob/$ref/" pandoc report.md \
  -f gfm+implicit_figures -t html5 --standalone --embed-resources --section-divs \
  --lua-filter "$here/filter.lua" --css "$here/style.css" \
  -M lang=en -M pagetitle="$title" -o "$tmp/report.html"
node "$here/print.js" "$tmp/report.html" "$root/report/report.pdf" \
  "Wang · version $version"
echo "Wrote report/report.pdf (links to $repo at $ref)"
