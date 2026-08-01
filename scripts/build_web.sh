#!/usr/bin/env bash
#
# Release build for Build4All Manager on the web, tuned for first-load time.
#
# Usage:
#   ./scripts/build_web.sh
#   ./scripts/build_web.sh --base-href /manager/
#   API_ROOT=https://api.example.com ./scripts/build_web.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

BASE_HREF="/"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-href)
      BASE_HREF="$2"
      shift 2
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -n "${API_ROOT:-}" ]]; then
  EXTRA_ARGS+=("--dart-define=API_ROOT=${API_ROOT}")
fi

echo "==> flutter pub get"
flutter pub get

echo "==> building web (base-href: ${BASE_HREF})"

# Flag notes — these are the ones that matter for the white-screen problem:
#
#   --no-web-resources-cdn
#       Serve CanvasKit from our own origin instead of www.gstatic.com. Saves a
#       separate DNS + TLS handshake to a third-party host on every cold load,
#       lets the file ride the connection we already have open, and makes the
#       app work in networks where gstatic.com is slow or blocked.
#
#   --pwa-strategy=offline-first
#       Precache the app shell in the service worker, so the second visit and
#       every visit after it start from local cache instead of the network.
#
#   --tree-shake-icons
#       On by default in release; kept explicit because this app pulls in three
#       icon fonts (material_symbols_icons, font_awesome_flutter, ionicons) and
#       shipping them whole costs well over a megabyte.
flutter build web \
  --release \
  --base-href "${BASE_HREF}" \
  --no-web-resources-cdn \
  --pwa-strategy=offline-first \
  --tree-shake-icons \
  "${EXTRA_ARGS[@]}"

echo
echo "==> build/web contents (largest first)"
du -h -d 1 build/web | sort -hr | head -20
echo
echo "==> main bundle"
ls -lh build/web/main.dart.js 2>/dev/null || true

cat <<'EOF'

Done. Deployment checklist for a fast first load:

  1. Enable gzip or brotli on the server. main.dart.js compresses to roughly a
     third of its size; serving it uncompressed is the single most expensive
     mistake here.
  2. Cache the hashed assets hard, and never cache the entry points:
       Cache-Control: public, max-age=31536000, immutable
         -> canvaskit/*, assets/*, *.js.map
       Cache-Control: no-cache
         -> index.html, flutter_service_worker.js, flutter_bootstrap.js
     Getting this wrong on index.html means users keep an old service worker
     and never see new releases.
  3. Serve over HTTP/2 or HTTP/3 if the host supports it.

EOF
