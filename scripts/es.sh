#!/usr/bin/env bash
set -euo pipefail
set +x
cd "$(dirname "$0")/.."
method=${1:?Usage: bash scripts/es.sh METHOD /path [JSON-file]}
path=${2:?Supply an API path}
[[ "$path" == /* ]] || { echo "Path must start with /" >&2; exit 1; }
args=(--silent --show-error --fail-with-body --noproxy '*'
  --cacert .secrets/es-ca.crt --netrc-file .secrets/es.netrc
  --resolve elk-es-http.logging.svc:9200:127.0.0.1
  -X "$method" "https://elk-es-http.logging.svc:9200$path")
if [[ -n "${3:-}" ]]; then
  args+=(-H "Content-Type: application/json" --data-binary "@$3")
fi
curl "${args[@]}"
echo