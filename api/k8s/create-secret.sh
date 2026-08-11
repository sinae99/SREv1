#!/usr/bin/env bash
set -euo pipefail

# Build DATABASE_URL from CNPG app secret (sina-db-app) — password never stored in git.
NAMESPACE_APP="${NAMESPACE_APP:-geoapi}"
NAMESPACE_DB="${NAMESPACE_DB:-postgres}"
SECRET_DB="${SECRET_DB:-sina-db-app}"
SECRET_APP="${SECRET_APP:-geoapi-db}"
HOST="${HOST:-sina-db-rw.postgres.svc.cluster.local}"
PORT="${PORT:-5432}"

if ! kubectl -n "${NAMESPACE_DB}" get secret "${SECRET_DB}" >/dev/null 2>&1; then
  echo "Could not find secret ${SECRET_DB} in namespace ${NAMESPACE_DB}"
  exit 1
fi

USER=$(kubectl -n "${NAMESPACE_DB}" get secret "${SECRET_DB}" -o jsonpath='{.data.username}' | base64 --decode)
PASS=$(kubectl -n "${NAMESPACE_DB}" get secret "${SECRET_DB}" -o jsonpath='{.data.password}' | base64 --decode)
DB=$(kubectl -n "${NAMESPACE_DB}" get secret "${SECRET_DB}" -o jsonpath='{.data.dbname}' | base64 --decode 2>/dev/null || true)
if [[ -z "${DB}" ]]; then
  DB="geoapi"
fi

DATABASE_URL="postgresql://${USER}:${PASS}@${HOST}:${PORT}/${DB}"

kubectl get ns "${NAMESPACE_APP}" >/dev/null 2>&1 || kubectl create ns "${NAMESPACE_APP}"

kubectl -n "${NAMESPACE_APP}" create secret generic "${SECRET_APP}" \
  --from-literal=DATABASE_URL="${DATABASE_URL}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Applied secret ${SECRET_APP} in namespace ${NAMESPACE_APP}"
echo "  Host: ${HOST}"
echo "  Port: ${PORT}"
echo "  DB  : ${DB}"
echo "  User: ${USER}"
