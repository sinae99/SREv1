# Source mirror, now annotated

This tree is the documented copy of the repository.

## What changed from the raw mirror

- Files now contain inline comments and block explanations.
- Terraform files explain providers, data sources, locals, resources, and outputs.
- Shell scripts explain input, output, control flow, and data handoff.
- Kubernetes YAML files explain each manifest field and why it exists.
- Python files explain request handling, caching, metrics, and tests.

## How to navigate

1. Start with `infra/` because the rest of the system depends on Terraform outputs.
2. Continue to `kubernetes/` to see how the cluster is installed.
3. Read `database/` and `observability/` for the stateful and monitoring layers.
4. Finish with `api/` to understand the runtime application.

## Note

The sample outputs under `kubernetes/output/` remain as evidence snapshots, but the code and manifests are the main interview material.
