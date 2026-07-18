#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_dir="${1:-${PWD}}"

if [[ ! -d "${project_dir}" ]]; then
  echo "Project directory does not exist: ${project_dir}" >&2
  exit 1
fi

project_dir="$(cd "${project_dir}" && pwd)"
shift "$(( $# > 0 ? 1 : 0 ))"

if [[ $# -eq 0 ]]; then
  set -- .
fi

set -a
# Resolved from this script's canonical repository path.
# shellcheck disable=SC1091
source "${repo_dir}/versions.env"
set +a

export PROJECT_DIR="${project_dir}"
compose_run_args=(run --quiet --rm)
if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]]; then
  compose_run_args+=(--env NVIM_NOTTYFAST=1)
elif [[ -n "${NVIM_NOTTYFAST:-}" ]]; then
  compose_run_args+=(--env "NVIM_NOTTYFAST=${NVIM_NOTTYFAST}")
fi

docker compose --project-directory "${repo_dir}" --file "${repo_dir}/compose.yaml" \
  "${compose_run_args[@]}" editor "$@"
