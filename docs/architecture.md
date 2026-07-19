# Architecture

The workbench deliberately freezes the editor and exposes only a narrow host boundary.

```text
macOS / SSH client
├── dev launcher + per-project zellij session
├── Codex, Git, tests, project runtimes (host tabs)
└── project directory (bind mount)
          │
          ▼
read-only Neovim container, network disabled
├── Neovim and Lua configuration
├── Deno + pre-warmed module cache
├── generated dpp state
├── pinned plugin checkouts
├── compiled Tree-sitter parsers
├── LSP servers and formatters
└── temporary cache/state in tmpfs
```

The image uses a multi-stage build. Compilers, download tools, npm, archive tools, and
the Tree-sitter CLI exist only in the builder. The final Debian slim runtime receives
the verified binaries, Pyright package, plugin files without Git histories, and compiled
parsers.

The host-side `dev` launcher is intentionally separate from the image. It creates or
reattaches to a deterministic zellij session for the selected project. Only the Neovim tab
enters Docker; Codex, Git, and tests retain normal access to macOS credentials, runtimes,
and developer tooling. Those three host tabs are created only when the selected directory
is inside a Git working tree; non-Git directories receive an editor-only session. Session
identity includes the canonical project path so directories with the same name do not
collide.

## Frozen boundary

The image contains the Neovim binary, Deno, configuration, generated dpp state, plugin
working trees, parsers, language servers, formatters, and search tools. Deno resolves the
dpp/ddu JSR modules during the build; its completed cache is copied into the runtime.
Configuration, Deno modules, the pre-fetched WASM, dpp state, and plugin directories are
made non-writable during the build. Runtime networking is disabled, and the root
filesystem is read-only. ddu's import-map transformer receives one isolated tmpfs for
transient generated modules; it cannot modify the frozen Deno inputs.

Both plain and Nerd Font display plugins are frozen into the same image. Because glyphs
are rendered by the terminal outside the container, font availability is declared at
launch with `NVIM_NERD_FONT=1`; omission selects the safe plain mode. This changes only
configuration choices and does not cross or mutate the frozen boundary.

The Debian slim base image is pinned by multi-platform digest. Directly downloaded binaries
are pinned by version and SHA-256. The dpp core is pinned in `config/nvim/dpp/core.tsv`;
all other plugins use exact `rev` values in `config/nvim/dpp/plugins.toml`. The builder
generates dpp state and installs those revisions before Git histories are discarded.
Debian packages are captured in the completed image, but an arbitrarily late rebuild can
still resolve newer packages from the Debian archive. The exported image is therefore the
authoritative long-term artifact. Each build also writes `/opt/workbench/manifest.txt`,
recording installed package versions, tool versions, and the actual plugin commits.

The runtime exposes only `:DppInfo`. Install, update, state-rebuild, cache-deletion, and
cleanup commands are excluded because they would mutate the frozen boundary. Those
operations belong to the candidate image build.

## Host boundary

Only the selected project directory is mounted at `/workspace`. Mac-side Git, Codex,
test runners, Docker tooling, Keychain, and GUI applications stay outside the editor.
This avoids mounting SSH keys, the Docker socket, or the whole home directory.

OSC 52 sends copy operations through the terminal protocol. It works without `pbcopy`
inside the Linux container. Every terminal multiplexer and SSH client in the path must
pass OSC 52 through; paste support varies by terminal, so normal terminal paste remains
the fallback.

## State

Cache, general state, and ddu's generated import-map modules use tmpfs and disappear with
the container. The `shada/` child directory is the sole persistent editor-state exception:
it uses the single `nvim-workbench-shada` Docker volume. This intentionally shares
`v:oldfiles`, marks, registers, and search history across all projects. Since each project
appears as `/workspace` inside its container, path collisions are accepted as part of the
global-history model. Project edits remain on macOS through the bind mount; config,
plugins, and Deno inputs remain read-only.
