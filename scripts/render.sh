#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./lab.env
: "${STACK_VERSION:?}" "${ECK_VERSION:?}" "${STORAGE_CLASS:?}" "${DEMO_IMAGE:?}"
[[ "$STORAGE_CLASS" != REPLACE* ]] || { echo "Set STORAGE_CLASS in lab.env" >&2; exit 1; }
command -v envsubst >/dev/null
mkdir -p rendered
cp manifests/00-namespaces.yaml rendered/
cp manifests/60-network-policy.yaml rendered/
for file in manifests/*.tmpl; do
  # Only replace these three variables. Preserve ECK and Filebeat runtime variables.
  envsubst '${STACK_VERSION} ${STORAGE_CLASS} ${DEMO_IMAGE}' < "$file" > "rendered/$(basename "${file%.tmpl}")"
done
echo "Rendered manifests. Review them before applying individual stages."