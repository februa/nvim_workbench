#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_dir}"

for script in bin/* scripts/*.sh scripts/container-smoke-test scripts/capture-manifest; do
  bash -n "${script}"
done

python3 - <<'PY'
import pathlib
import tomllib

dpp_dir = pathlib.Path("config/nvim/dpp")
plugins = tomllib.loads((dpp_dir / "plugins.toml").read_text())["plugins"]
selection = tomllib.loads((dpp_dir / "selection.toml").read_text())

sections = ("adopted", "rejected", "deferred")
repos_by_section = {
    section: [item["repo"] for item in selection[section]] for section in sections
}
all_selected = [repo for section in sections for repo in repos_by_section[section]]
if len(all_selected) != len(set(all_selected)):
    raise SystemExit("selection.toml contains a duplicate repository")

active = {plugin["repo"] for plugin in plugins}
adopted = set(repos_by_section["adopted"])
if active != adopted:
    missing = sorted(active - adopted)
    inactive = sorted(adopted - active)
    raise SystemExit(
        f"plugins.toml and adopted selection differ: missing={missing}, inactive={inactive}"
    )
PY
awk -F '\t' 'NF != 2 || split($1, parts, "/") != 2 || length($2) != 40 || $2 ~ /[^0-9a-f]/ { exit 1 }' config/nvim/dpp/core.tsv

if command -v docker >/dev/null 2>&1; then
  docker compose --file compose.yaml config --quiet
else
  echo "Docker not found: skipped Compose validation"
fi

echo "Static checks: OK"
