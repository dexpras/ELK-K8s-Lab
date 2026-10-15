#!/usr/bin/env bash
set -euo pipefail
set +x
cd "$(dirname "$0")/.."
umask 077
mkdir -p .secrets
kubectl -n logging get secret elk-es-http-certs-public \
  -o jsonpath='{.data.ca\.crt}' | base64 --decode > .secrets/es-ca.crt
password=$(kubectl -n logging get secret elk-es-elastic-user \
  -o jsonpath='{.data.elastic}' | base64 --decode)
[[ -n "$password" ]] || { echo "Elasticsearch password is empty" >&2; exit 1; }
printf 'machine elk-es-http.logging.svc\nlogin elastic\npassword %s\n' "$password" > .secrets/es.netrc
unset password
chmod 600 .secrets/es.netrc
echo "Local admin credentials saved privately. Do not commit or share .secrets."