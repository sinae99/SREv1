# CI/CD — high-level documentation

This repository documents the delivery flow rather than the full workflow file.

## What the pipeline does

- tests the API
- builds the container image
- publishes it to GHCR
- deploys the manifests to Kubernetes

## Interview framing

Mention CI/CD as the final delivery layer, but keep the focus on the infrastructure, cluster, database, observability, and API layers because they form the core challenge story.
