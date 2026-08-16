#!/usr/bin/env bash

# Strict mode makes the secret lookup predictable.
set -euo pipefail

NAMESPACE="postgres"
SECRET_NAME="sina-db-app"

# Refuse to print credentials if the expected secret is missing.
if ! kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" >/dev/null 2>&1; then
  echo "Could not find secret ${SECRET_NAME} in namespace ${NAMESPACE}"
  echo "Try: kubectl get secret -n ${NAMESPACE}"
  exit 1
fi

# Decode the secret fields into readable values.
USER=$(kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" -o jsonpath='{.data.username}' | base64 --decode)
PASS=$(kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" -o jsonpath='{.data.password}' | base64 --decode)
DB=$(kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" -o jsonpath='{.data.dbname}' | base64 --decode 2>/dev/null || true)

# CNPG normally sets the application database to geoapi; keep that as fallback.
if [[ -z "${DB}" ]]; then
  DB="geoapi"
fi

echo "sina-db credentials (geoapi):"
echo "  Host: sina-db-rw.postgres.svc.cluster.local"
echo "  Port: 5432"
echo "  DB  : ${DB}"
echo "  User: ${USER}"
echo "  Pass: ${PASS}"
