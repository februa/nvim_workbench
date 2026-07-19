#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_dir}"

set -a
source versions.env
set +a

docker image inspect "${NVIM_IMAGE}" >/dev/null
for nerd_font in 0 1; do
  echo "Smoke testing NVIM_NERD_FONT=${nerd_font}"
  docker run --rm \
    --network none \
    --read-only \
    --env "NVIM_NERD_FONT=${nerd_font}" \
    --tmpfs /tmp:mode=1777 \
    --tmpfs /home/nvim/.cache:uid=1000,gid=1000,mode=0700 \
    --tmpfs /home/nvim/.local/state/nvim:uid=1000,gid=1000,mode=0700 \
    --tmpfs /opt/deno-cache/import_map_importer:uid=1000,gid=1000,mode=0700 \
    --entrypoint /opt/workbench/scripts/container-smoke-test \
    "${NVIM_IMAGE}"
done

shada_volume="nvim-workbench-shada-smoke-$$"
cleanup() {
  docker volume rm --force "${shada_volume}" >/dev/null
}
trap cleanup EXIT

docker volume create "${shada_volume}" >/dev/null
docker run --rm \
  --network none \
  --read-only \
  --tmpfs /tmp:mode=1777 \
  --tmpfs /home/nvim/.cache:uid=1000,gid=1000,mode=0700 \
  --tmpfs /home/nvim/.local/state/nvim:uid=1000,gid=1000,mode=0700 \
  --tmpfs /opt/deno-cache/import_map_importer:uid=1000,gid=1000,mode=0700 \
  --volume "${shada_volume}:/home/nvim/.local/state/nvim/shada" \
  --entrypoint nvim \
  "${NVIM_IMAGE}" \
  --headless /opt/workbench/tests/fixtures/sample.lua "+qall!"
docker run --rm \
  --network none \
  --read-only \
  --tmpfs /tmp:mode=1777 \
  --tmpfs /home/nvim/.cache:uid=1000,gid=1000,mode=0700 \
  --tmpfs /home/nvim/.local/state/nvim:uid=1000,gid=1000,mode=0700 \
  --tmpfs /opt/deno-cache/import_map_importer:uid=1000,gid=1000,mode=0700 \
  --volume "${shada_volume}:/home/nvim/.local/state/nvim/shada" \
  --entrypoint nvim \
  "${NVIM_IMAGE}" \
  --headless "+luafile /opt/workbench/tests/shada-read.lua"
