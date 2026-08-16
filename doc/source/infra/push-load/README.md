# Push-load — image preload helper

This folder explains the optional image-preload path for environments where the nodes cannot pull images directly.

## Data flow

- input images or tarballs are defined in `config.yml`
- the playbook runs on the controller first
- Docker images are saved to tar files on the controller
- the tar files are copied to each VM
- the tar files are imported into `containerd` with `ctr -n k8s.io images import`
- the script verifies the result with `crictl images`

## Why it exists

It solves the "push/load" part of the challenge without involving the application stack directly: the cluster gets the images it needs even when normal pull access is limited.
