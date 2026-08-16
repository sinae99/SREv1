# Database — CloudNativePG walkthrough

This folder documents the PostgreSQL cache backend used by GeoAPI.

## Reading order

1. Install the CloudNativePG operator.
2. Create the `postgres` namespace.
3. Apply `cluster.yaml`.
4. Use `credentials.sh` to print the connection details.

## What matters in the design

- two instances for primary/standby behavior
- local persistent storage for the cache
- a simple database name and user for the API
- pod anti-affinity so replicas spread across workers
