#!/usr/bin/env bash
#
# Dipi screenshot harness.
#
# Integration tests capture only the Flutter surface (no status bar), so this
# script drives the release build with adb / uiautomator and uses
# `adb screencap` for full-device 1080×2400 shots.
#
# Usage:  tool/screenshots/capture.sh [dark|light|all]
#
# Output: shots/raw/<screen>-<theme>.png
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ADB="${ADB:-/home/mostafa/Android/Sdk/platform-tools/adb}"
SERIAL="${SERIAL:-emulator-5556}"
PKG="${PKG:-com.yourname.dipi}"
OUT="$ROOT/shots/raw"
THEME="${1:-all}"
DUMP="/tmp/dipi-uidump.xml"
TAP_UI="$ROOT/tool/screenshots/tap_ui.py"

A() { "$ADB" -s "$SERIAL" "$@"; }

tap_xy() { A shell input tap "$1" "$2"; sleep 0.8; }
back() { A shell input keyevent 4; sleep 0.8; }
swipe_up() { A shell input swipe 540 1800 540 900 320; sleep 1.0; }
swipe_big() { A shell input swipe 540 2100 540 400 600; sleep 1.1; }

dump_ui() {
  A shell uiautomator dump /sdcard/window_dump.xml >/dev/null 2>&1 || true
  A pull /sdcard/window_dump.xml "$DUMP" >/dev/null 2>&1 || true
}

# Tap the first node whose text or content-desc equals / contains $1.
# Falls back to the supplied x y when the node is missing.
tap_label() {
  local needle="$1" fx="${2:-}" fy="${3:-}" mode="${4:-contains}" nth="${5:-0}"
  dump_ui
  local point=""
  if [[ -f "$DUMP" ]]; then
    if [[ "$mode" == "exact" ]]; then
      point="$(python3 "$TAP_UI" "$DUMP" "$needle" --nth "$nth" || true)"
    else
      point="$(python3 "$TAP_UI" "$DUMP" "$needle" --contains --nth "$nth" || true)"
    fi
  fi
  if [[ -n "$point" ]]; then
    # shellcheck disable=SC2086
    tap_xy $point
    return 0
  fi
  if [[ -n "$fx" && -n "$fy" ]]; then
    tap_xy "$fx" "$fy"
    return 0
  fi
  echo "  ! missing UI node: $needle" >&2
  return 1
}

dismiss_anr() {
  dump_ui
  if [[ -f "$DUMP" ]] && grep -qiE 'isn.t responding|not responding' "$DUMP"; then
    echo '  ! ANR dialog, choosing Wait'
    tap_label "Wait" 540 1450 contains
    sleep 2
  fi
}

require_app() {
  if ! A shell dumpsys activity activities 2>/dev/null | grep -q "topResumedActivity.*$PKG"; then
    echo "  ! relaunching $PKG"
    A shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
    sleep 6
    wait_ready
  fi
  dismiss_anr
}

shot() {
  require_app
  sleep 0.8
  A exec-out screencap -p > "$OUT/$1-$2.png"
  echo "  captured $1-$2.png"
}

prepare_device() {
  A shell settings put global sysui_demo_allowed 1
  A shell settings put global window_animation_scale 0
  A shell settings put global transition_animation_scale 0
  A shell settings put global animator_duration_scale 0
  A shell cmd overlay enable com.android.internal.systemui.navbar.gestural
  A shell am broadcast -a com.android.systemui.demo -e command enter >/dev/null
  A shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941 >/dev/null
  A shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false >/dev/null
  A shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 -e mobile hide >/dev/null
  A shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false >/dev/null
}

wait_ready() {
  local i
  for i in $(seq 1 40); do
    dismiss_anr
    dump_ui
    if [[ -f "$DUMP" ]] && grep -q 'تقویم' "$DUMP"; then
      sleep 1
      return 0
    fi
    local focus
    focus=$(A shell dumpsys window 2>/dev/null | grep -m1 -E 'mCurrentFocus|mFocusedApp' || true)
    if echo "$focus" | grep -qi 'not responding'; then
      echo '  ! ANR via window focus, tapping Wait'
      tap_xy 540 1450
      sleep 2
    fi
    sleep 2
  done
  echo "  ! timed out waiting for calendar" >&2
  return 1
}

launch_fresh() {
  A shell am force-stop "$PKG"
  sleep 1
  A shell pm clear "$PKG" >/dev/null
  sleep 1
  A shell cmd uimode night "$1"
  sleep 2
  prepare_device
  A logcat -c
  A shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  for _ in $(seq 1 40); do
    sleep 1
    if A logcat -d 2>/dev/null | grep -q 'Dipi demo data'; then
      break
    fi
  done
  wait_ready
  sleep 2
}

# Open a worked day that is not today, prefer one whose card says «در انتظار».
select_pending_day() {
  dump_ui
  local i
  for i in 0 1 2 3 4 5 6 7 8 9; do
    local point
    point="$(python3 "$TAP_UI" "$DUMP" "روز کاری" --contains --nth "$i" || true)"
    [[ -z "$point" ]] && continue
    local desc
    desc="$(python3 - "$DUMP" "$i" <<'PY'
import sys, xml.etree.ElementTree as Et
root = Et.parse(sys.argv[1]).getroot()
n = 0
for node in root.iter():
    hay = (node.attrib.get("text","") + " " + node.attrib.get("content-desc",""))
    if "روز کاری" in hay:
        if n == int(sys.argv[2]):
            print(hay)
            break
        n += 1
PY
)"
    if [[ "$desc" == *امروز* ]]; then
      continue
    fi
    # shellcheck disable=SC2086
    tap_xy $point
    sleep 0.6
    dump_ui
    if grep -q 'در انتظار' "$DUMP"; then
      return 0
    fi
  done
  # Fallback: previously measured pending cell on Mehr 1405.
  tap_xy 818 640
}

# Switch system night mode without wiping the DB. A second `pm clear`
# after a cold start is what produced the splash/ANR dark shots.
switch_theme() {
  A shell cmd uimode night "$1"
  sleep 2
  prepare_device
  sleep 1
}

capture_theme() {
  local theme="$1" night="$2"
  echo "== $theme =="
  A shell cmd uimode night "$night"
  sleep 1
  prepare_device

  # 1 calendar, a paid day selected (today — seeder marks it paid).
  tap_label "امروز" 130 985 contains
  shot 1-calendar-paid "$theme"

  # 2 calendar, a pending day selected.
  select_pending_day
  shot 2-calendar-pending "$theme"

  # 3 add workday form (center primary action of the floating nav).
  tap_xy 540 2200
  sleep 0.8
  shot 3-add-workday "$theme"
  back

  # 4 employers list.
  tap_label "کارفرماها" 741 2200 contains
  shot 4-employers "$theme"

  # 5 employer detail (first card in the name-sorted list).
  tap_xy 535 430
  sleep 0.8
  shot 5-employer-detail "$theme"
  back

  # 6 payments list.
  tap_label "پرداخت‌ها" 339 2200 contains
  shot 6-payments "$theme"

  # 7 add payment form (page FAB, above the floating nav).
  tap_xy 188 2018
  sleep 0.8
  shot 7-add-payment "$theme"
  back

  # 8 stats — scroll so the monthly trend is visible with employer cards.
  tap_label "آمار" 137 2200 contains
  sleep 0.5
  swipe_big
  shot 8-stats "$theme"

  # 9 settings (backup section).
  tap_label "تنظیمات" 60 168 exact
  sleep 0.5
  swipe_up
  shot 9-settings "$theme"
  back
}

mkdir -p "$OUT"
prepare_device
case "$THEME" in
  dark)
    launch_fresh yes
    capture_theme dark yes
    ;;
  light)
    launch_fresh no
    capture_theme light no
    ;;
  all)
    launch_fresh yes
    capture_theme dark yes
    switch_theme no
    capture_theme light no
    ;;
  *) echo "usage: $0 [dark|light|all]" >&2; exit 1 ;;
esac
echo "done -> $OUT"
