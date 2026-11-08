#!/usr/bin/env bash
# Signs the add-on as unlisted ("On your own") on addons.mozilla.org and saves the
# signed .xpi to dist/. Reads the AMO API keys from the macOS keychain:
#   security add-generic-password -s amo-jwt-issuer -a "$USER" -w '<issuer>'
#   security add-generic-password -s amo-jwt-secret -a "$USER" -w '<secret>'
# Keys: https://addons.mozilla.org/developers/addon/api/key/
set -euo pipefail
cd "$(dirname "$0")/.."

WEB_EXT_API_KEY=$(security find-generic-password -s amo-jwt-issuer -w)
WEB_EXT_API_SECRET=$(security find-generic-password -s amo-jwt-secret -w)
export WEB_EXT_API_KEY WEB_EXT_API_SECRET

npx --yes web-ext sign --channel=unlisted --source-dir . --artifacts-dir dist \
  --ignore-files 'store/**' 'scripts/**' 'assets/**' 'dist/**' 'CLAUDE.md' 'README.md' '.*'
ls -t dist/*.xpi | head -1
