#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_dir}"

for script in bin/* scripts/*.sh scripts/container-smoke-test scripts/capture-manifest; do
  bash -n "${script}"
done

python3 -m json.tool config/nvim/lazy-lock.json >/dev/null

if command -v docker >/dev/null 2>&1; then
  docker compose --file compose.yaml config --quiet
else
  echo "Docker not found: skipped Compose validation"
fi

echo "Static checks: OK"
