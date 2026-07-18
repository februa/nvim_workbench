#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_dir}"

set -a
source versions.env
set +a

docker build --tag "${NVIM_IMAGE}" .
docker image inspect "${NVIM_IMAGE}" --format 'Built {{.RepoTags}}\nImage ID: {{.Id}}'
