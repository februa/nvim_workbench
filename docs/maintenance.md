# Updating without breaking stable

Never rebuild the stable tag in place as the first update step.

1. Change versions and checksums in `Dockerfile` and `versions.env`.
2. Update exact plugin revisions in `config/nvim/dpp/core.tsv` or the `rev` fields in
   `config/nvim/dpp/plugins.toml` on a temporary candidate branch.
3. Change `NVIM_IMAGE` to a dated candidate tag.
4. Run `./scripts/build.sh` and `./scripts/smoke-test.sh`.
5. Open the fixture files and one real project through `./scripts/run.sh`.
6. Export the candidate with `./scripts/export.sh`.
7. Promote it to a new dated stable tag. Keep the preceding stable archive.

The smoke test is intentionally run with no network and a read-only root filesystem.
That proves startup, plugins, parsers, tools, and OSC 52 configuration do not fetch or
mutate editor dependencies at runtime.

For disaster recovery, retain all three:

- this Git repository (recipe and configuration),
- `config/nvim/dpp/core.tsv` and `config/nvim/dpp/plugins.toml` (plugin revisions),
- the exported `.tar.gz`, checksum, and metadata (known-working result).
