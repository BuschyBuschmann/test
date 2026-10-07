#!/bin/bash
# Installiert das Flutter-SDK (aktuelles Stable) in Cloud-Sessions, falls es fehlt.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_DIR=/opt/flutter
BASE_URL=https://storage.googleapis.com/flutter_infra_release/releases

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  ARCHIVE=$(curl -fsSL "$BASE_URL/releases_linux.json" | python3 -c \
    "import json,sys;d=json.load(sys.stdin);h=d['current_release']['stable'];print(next(r['archive'] for r in d['releases'] if r['hash']==h))")
  curl -fsSL "$BASE_URL/$ARCHIVE" | tar -xJ -C "$(dirname "$FLUTTER_DIR")"
fi

git config --global --get-all safe.directory | grep -qx "$FLUTTER_DIR" \
  || git config --global --add safe.directory "$FLUTTER_DIR"

export PATH="$FLUTTER_DIR/bin:$PATH"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$FLUTTER_DIR/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

flutter --disable-analytics >/dev/null 2>&1 || true
flutter precache --no-android --no-ios >/dev/null
