#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_dir}"

set -a
source versions.env
set +a

mkdir -p artifacts
safe_tag="${NVIM_IMAGE//[:\/]/-}"
archive="artifacts/${safe_tag}.tar.gz"
metadata="artifacts/${safe_tag}.metadata.txt"
manifest="artifacts/${safe_tag}.manifest.txt"

docker image inspect "${NVIM_IMAGE}" > "${metadata}"
docker run --rm --network none --entrypoint cat "${NVIM_IMAGE}" /opt/workbench/manifest.txt > "${manifest}"
docker save "${NVIM_IMAGE}" | gzip -9 > "${archive}"
shasum -a 256 "${archive}" > "${archive}.sha256"

echo "Exported ${archive}"
echo "Metadata ${metadata}"
echo "Manifest ${manifest}"
