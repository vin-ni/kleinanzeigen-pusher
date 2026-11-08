#!/usr/bin/env bash
# Builds the zip to upload to addons.mozilla.org (AMO), after linting it with web-ext.
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(node -p 'require("./manifest.json").version')
out="dist/kleinanzeigen-pusher-firefox-$version.zip"

npx --yes web-ext lint --source-dir . --ignore-files 'store/**' 'scripts/**' 'assets/**' 'dist/**' 'CLAUDE.md' 'README.md'

mkdir -p dist
rm -f "$out"
zip -qr "$out" manifest.json src images -x '.*'
echo "$out"
