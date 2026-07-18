#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_dir}"

set -a
source versions.env
set +a

docker image inspect "${NVIM_IMAGE}" >/dev/null
docker run --rm \
  --network none \
  --read-only \
  --tmpfs /tmp:mode=1777 \
  --tmpfs /home/nvim/.cache:uid=1000,gid=1000,mode=0700 \
  --tmpfs /home/nvim/.local/state:uid=1000,gid=1000,mode=0700 \
  --entrypoint /opt/workbench/scripts/container-smoke-test \
  "${NVIM_IMAGE}"
