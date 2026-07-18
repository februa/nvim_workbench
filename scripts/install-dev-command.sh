#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install_dir="${DEV_BIN_DIR:-${HOME}/.local/bin}"

mkdir -p "${install_dir}"
ln -sfn "${repo_dir}/bin/dev" "${install_dir}/dev"
ln -sfn "${repo_dir}/bin/nvim" "${install_dir}/nvim"

echo "Installed dev -> ${repo_dir}/bin/dev"
echo "Installed nvim -> ${repo_dir}/bin/nvim"
case ":${PATH}:" in
  *":${install_dir}:"*) ;;
  *)
    echo "Add ${install_dir} to PATH before using dev." >&2
    ;;
esac
