#!/usr/bin/env bash
#
# Fails if anything under lib/ writes to the console.
#
# `print` is covered by the `avoid_print` lint, but `debugPrint`,
# `debugPrintStack` and Dio's `LogInterceptor` have no lint of their own — and
# all of them keep emitting in release builds, where the output is readable by
# anyone with access to the device (logcat / Console.app / browser console).
#
# Usage:
#   ./scripts/check_no_logs.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

pattern='(^|[^A-Za-z0-9_.])(print|debugPrint|debugPrintStack)\(|LogInterceptor|dart:developer'

if matches=$(grep -rnE "$pattern" lib --include='*.dart'); then
  echo "Console logging found in lib/ — remove it before shipping:" >&2
  echo "$matches" >&2
  exit 1
fi

echo "OK: no console logging in lib/"
