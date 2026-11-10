#!/usr/bin/env bash
# يبني XnfAlMufakkir.ipa (غير موقّع) على macOS باستخدام Theos.
# الاستخدام:  THEOS=~/theos ./scripts/make-ipa.sh
set -euo pipefail

cd "$(dirname "$0")/.."

MAKE_BIN="${MAKE_BIN:-}"
if [ -z "$MAKE_BIN" ]; then
  if command -v gmake >/dev/null 2>&1; then MAKE_BIN=gmake; else MAKE_BIN=make; fi
fi

if [ -z "${THEOS:-}" ]; then
  echo "لازم تحدد مسار Theos، مثال: THEOS=~/theos ./scripts/make-ipa.sh" >&2
  exit 1
fi
export THEOS

"$MAKE_BIN" clean
"$MAKE_BIN" FINALPACKAGE=1

APP_PATH="$(find .theos/_/Applications -maxdepth 1 -name '*.app' | head -n 1)"
if [ -z "$APP_PATH" ]; then
  echo "ما لقيت ملف .app — تأكد إن البناء نجح." >&2
  exit 1
fi

rm -rf Payload XnfAlMufakkir.ipa
mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -qry XnfAlMufakkir.ipa Payload
rm -rf Payload

echo "تم إنشاء: $(pwd)/XnfAlMufakkir.ipa"
