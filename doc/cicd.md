# CI/CD Summary

This repository only documents the delivery flow in `cicd/README.md`; the focus is on the platform challenge rather than a full pipeline implementation.

## What the pipeline does

- run tests with `pytest`
- build the application image
- publish the image to GitHub Container Registry
- deploy the Kubernetes manifests

## Interview framing

- Mention this as the final step of the platform lifecycle.
- Keep the emphasis on the infrastructure, cluster, application, and observability layers, because those are the core challenge deliverables.
