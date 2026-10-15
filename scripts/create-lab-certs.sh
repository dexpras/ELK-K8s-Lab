#!/usr/bin/env bash
set -euo pipefail
set +x
cd "$(dirname "$0")/.."
umask 077
mkdir -p .secrets
[[ ! -e .secrets/ca.key ]] || { echo "CA exists. Do not replace a live CA with this script." >&2; exit 1; }
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out .secrets/ca.key
openssl req -x509 -new -sha256 -days 365 -key .secrets/ca.key \
  -out .secrets/ca.crt -subj "/CN=ELK lab ingestion CA" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out .secrets/logstash.key
openssl req -new -key .secrets/logstash.key -out .secrets/logstash.csr \
  -subj "/CN=ingest-ls-beats.logging.svc"
cat > .secrets/server.ext <<'EOF'
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:ingest-ls-beats,DNS:ingest-ls-beats.logging,DNS:ingest-ls-beats.logging.svc,DNS:ingest-ls-api.logging.svc
EOF
openssl x509 -req -sha256 -days 90 -in .secrets/logstash.csr \
  -CA .secrets/ca.crt -CAkey .secrets/ca.key -CAcreateserial \
  -extfile .secrets/server.ext -out .secrets/logstash.crt
# The Beats input requires a PEM PKCS8 private key.
openssl pkcs8 -topk8 -nocrypt -in .secrets/logstash.key -out .secrets/logstash.pkcs8.key
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out .secrets/filebeat.key
openssl req -new -key .secrets/filebeat.key -out .secrets/filebeat.csr \
  -subj "/CN=elk-lab-filebeat"
cat > .secrets/client.ext <<'EOF'
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=clientAuth
EOF
openssl x509 -req -sha256 -days 90 -in .secrets/filebeat.csr \
  -CA .secrets/ca.crt -CAkey .secrets/ca.key -CAserial .secrets/ca.srl \
  -extfile .secrets/client.ext -out .secrets/filebeat.crt
openssl verify -CAfile .secrets/ca.crt .secrets/logstash.crt .secrets/filebeat.crt
kubectl -n logging create secret generic logstash-ingest-tls \
  --from-file=tls.crt=.secrets/logstash.crt \
  --from-file=tls.key=.secrets/logstash.pkcs8.key --from-file=ca.crt=.secrets/ca.crt \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n logging-agents create secret generic filebeat-client-tls \
  --from-file=tls.crt=.secrets/filebeat.crt \
  --from-file=tls.key=.secrets/filebeat.key --from-file=ca.crt=.secrets/ca.crt \
  --dry-run=client -o yaml | kubectl apply -f -
echo "Lab certificates installed. Keep the CA private key offline; renew leaves before 90 days."