# PostgreSQL with CloudNativePG

The database layer uses the CloudNativePG operator to run a two-instance PostgreSQL cluster for GeoAPI. One instance acts as the primary and the second as a streaming replica, with pod anti-affinity encouraging placement on different Kubernetes workers.

## Database Topology

| Item | Value |
|---|---|
| Operator | CloudNativePG `1.30.0` |
| Operator namespace | `cnpg-system` |
| Database namespace | `postgres` |
| Cluster name | `sina-db` |
| Instances | `2` |
| Application database | `geoapi` |
| Application owner | `geoapi` |
| Storage class | `local-path` |
| Storage per instance | `5Gi` |

## Directory Structure

```text
database/
├── cluster.yaml       # CloudNativePG Cluster resource
└── credentials.sh     # Reads application credentials from the generated Secret
```

## Deployment

### 1. Install the Operator

```bash
kubectl apply --server-side -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.30/releases/cnpg-1.30.0.yaml
```

```bash
kubectl get pods -n cnpg-system
```

### 2. Create the Database Namespace

```bash
kubectl create namespace postgres
```

### 3. Apply the PostgreSQL Cluster

```bash
cd database
kubectl apply -f cluster.yaml
```

## Cluster Configuration

The manifest configures:

- PostgreSQL database and owner bootstrapping for `geoapi`.
- Two database instances.
- CPU and memory requests and limits.
- `shared_buffers` and `max_connections` parameters.
- Pod anti-affinity using the Kubernetes hostname topology key.
- Persistent volumes through the `local-path` storage class.

## Services

CloudNativePG creates service endpoints for the cluster:

| Service | Purpose |
|---|---|
| `sina-db-rw` | Routes connections to the current primary |
| `sina-db-ro` | Routes read-only connections to replicas |
| `sina-db-r` | Routes connections to any database instance |

GeoAPI uses:

```text
sina-db-rw.postgres.svc.cluster.local:5432
```

## Verification

```bash
kubectl get cluster -n postgres
kubectl get pods -n postgres -o wide
kubectl get pvc -n postgres
kubectl get svc -n postgres
```

Expected state:

- The `sina-db` Cluster is healthy.
- Both PostgreSQL pods are running.
- The primary and replica are placed on different workers when scheduling permits.
- Both persistent volume claims are bound.

## Credentials

CloudNativePG generates the `sina-db-app` Secret for the application owner. The helper prints the database name, username, and password:

```bash
./credentials.sh
```

Treat this output as sensitive.

## Connectivity Test

```bash
kubectl exec -n postgres -it sina-db-1 -- \
  psql -U geoapi -d geoapi -c 'SELECT version();'
```
