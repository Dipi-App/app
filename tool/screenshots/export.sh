#!/usr/bin/env bash
#
# Convert shots/raw PNGs to WebP (540 and 1080) and write screens.json + zip.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RAW="$ROOT/shots/raw"
EXPORT="$ROOT/export"
mkdir -p "$EXPORT"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing $1" >&2; exit 1; }; }
need convert
need zip
need identify

encode_webp() {
  local src="$1" dest="$2"
  if command -v cwebp >/dev/null 2>&1; then
    cwebp -q 85 -metadata none "$src" -o "$dest" >/dev/null
  else
    convert "$src" -strip -quality 85 "$dest"
  fi
}

SCREENS=(
  "1-calendar-paid|تقویم — روز پرداخت‌شده|تقویم شمسی دیپی با یک روز کاری پرداخت‌شده انتخاب شده و کارت همان روز باز است."
  "2-calendar-pending|تقویم — روز در انتظار|تقویم شمسی دیپی با یک روز کاری در انتظار دستمزد انتخاب شده و جزئیات همان روز دیده می‌شود."
  "3-add-workday|ثبت روزکار|فرم ثبت روزکار تازه در دیپی، با تاریخ شمسی و محل‌های پیشنهادی."
  "4-employers|فهرست کارفرماها|فهرست کارفرماها با شش عدد کارکرد، ساعت، دستمزد و پرداخت روی هر کارت."
  "5-employer-detail|جزئیات کارفرما|صفحهٔ یک کارفرما با مانده‌حساب، آمار و فهرست روزکارها."
  "6-payments|فهرست پرداخت‌ها|فهرست پرداخت‌ها با جمع دریافتی، فیلتر کارفرما و نوع پرداخت."
  "7-add-payment|ثبت پرداخت|فرم ثبت پرداخت تازه با نوع دستمزد، علی‌الحساب یا بازپرداخت هزینه."
  "8-stats|آمار|صفحهٔ آمار با نمودار ماهانه و کارت حساب هر کارفرما."
  "9-settings|تنظیمات و پشتیبان|صفحهٔ تنظیمات روی بخش پشتیبان‌گیری و خروجی فایل."
)

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1], ensure_ascii=False))' "$1"
}

{
  echo '{'
  echo '  "screens": ['
} > "$EXPORT/screens.json"

first=1
for entry in "${SCREENS[@]}"; do
  IFS='|' read -r id title alt <<<"$entry"
  for theme in dark light; do
    src="$RAW/${id}-${theme}.png"
    if [[ ! -f "$src" ]]; then
      echo "missing $src" >&2
      exit 1
    fi
    size="$(identify -format '%wx%h' "$src")"
    if [[ "$size" != "1080x2400" ]]; then
      echo "unexpected size $size for $src (want 1080x2400)" >&2
      exit 1
    fi
    convert "$src" -resize 540x1200 "$EXPORT/.tmp-540.png"
    convert "$src" -strip "$EXPORT/.tmp-1080.png"
    encode_webp "$EXPORT/.tmp-540.png" "$EXPORT/${id}-${theme}-540.webp"
    encode_webp "$EXPORT/.tmp-1080.png" "$EXPORT/${id}-${theme}-1080.webp"
  done

  if [[ "$first" -eq 0 ]]; then
    echo ',' >> "$EXPORT/screens.json"
  fi
  first=0
  cat >> "$EXPORT/screens.json" <<EOF
    {
      "id": $(json_escape "$id"),
      "title": $(json_escape "$title"),
      "alt": $(json_escape "$alt"),
      "files": {
        "dark": {
          "540": "${id}-dark-540.webp",
          "1080": "${id}-dark-1080.webp"
        },
        "light": {
          "540": "${id}-light-540.webp",
          "1080": "${id}-light-1080.webp"
        }
      }
    }
EOF
done

{
  echo
  echo '  ]'
  echo '}'
} >> "$EXPORT/screens.json"

rm -f "$EXPORT/.tmp-540.png" "$EXPORT/.tmp-1080.png"

(
  cd "$EXPORT"
  rm -f dipi-screens.zip
  zip -q dipi-screens.zip ./*.webp screens.json
)

echo "export ready -> $EXPORT"
ls -lh "$EXPORT" | sed -n '1,40p'
