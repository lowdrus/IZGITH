#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 nao foi encontrado." >&2
  exit 1
fi
if [ "${1:-}" = "" ]; then
  printf "ID da extensao (32 caracteres de a-p): "
  read EXTENSION_ID
else
  EXTENSION_ID="$1"
fi
BROWSER="${2:-chrome}"
python3 install_host.py --extension-id "$EXTENSION_ID" --browser "$BROWSER"
echo "Host IZGITH registrado. Reinicie o navegador."
