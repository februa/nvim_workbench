#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 path/to/nvim-workbench.tar.gz" >&2
  exit 2
fi

archive="$1"
test -f "${archive}"

if [[ -f "${archive}.sha256" ]]; then
  shasum -a 256 --check "${archive}.sha256"
fi

gzip -dc "${archive}" | docker load
