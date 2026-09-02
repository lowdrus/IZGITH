#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ID=${1:-}
BROWSER=${2:-chrome}
if [ -z "$ID" ]; then echo "uso: $0 EXTENSION_ID [chrome|chromium|edge|brave]" >&2; exit 2; fi
exec python3 "$HERE/install_host.py" --extension-id "$ID" --browser "$BROWSER"
