# nvim-workbench

A reproducible, frozen Neovim environment that runs in Docker while editing files kept
on macOS. Editor dependencies are baked into a versioned image; host-side Codex, Git,
tests, shells, and project runtimes remain independent.

## What is frozen

- Neovim 0.12.4 (official archive + SHA-256)
- Debian stable-slim build and runtime images (multi-platform digest)
- Deno 2.8.1 and a pre-warmed, read-only Deno module cache
- dpp.vim/ddu.vim plugins and generated dpp state (commit-pinned in `core.tsv` and `plugins.toml`)
- Tree-sitter CLI 0.26.11 at build time and compiled parsers at runtime
- Lua language server 3.18.2, Pyright 1.1.411, and clangd
- Ruff 0.15.22, StyLua 2.5.2, ShellCheck, ripgrep, and fd
- the complete Lua configuration, including OSC 52 clipboard support

Both Apple Silicon and Intel Macs are supported through Docker's `arm64` and `amd64`
build targets.

## Prerequisites

- Docker Desktop (or another Docker Engine with Compose v2)
- zellij 0.44 or newer for the `dev` launcher
- Codex CLI for Git workspaces that use the Codex tab
- a true-color terminal; Ghostty, WezTerm, iTerm2, and recent Terminal.app are suitable
- optional: an SSH client that passes OSC 52 sequences

## Build and verify

```bash
./scripts/build.sh
./scripts/smoke-test.sh
```

The build downloads dependencies once, verifies published checksums, restores pinned
plugins, compiles parsers, and runs the smoke test. The second command repeats the test
in both font modes with networking disabled and a read-only root filesystem.

## Edit a macOS project

Install the one-command launcher once after cloning this repository:

```bash
./scripts/install-dev-command.sh
```

Then start a complete project workspace from any project directory:

```bash
cd ~/work/my-project
dev
```

For the Dockerized editor without zellij, use `nvim` like a normal editor command:

```bash
cd ~/work/my-project
nvim .
nvim src/main.py
```

Plain symbols are the safe default. When the terminal or iPad SSH client uses a Nerd
Font, enable the icon display for that launch:

```bash
NVIM_NERD_FONT=1 nvim .
```

The same frozen image is used in both modes. The flag switches the ddu filename column,
lualine's rounded bubbles style, which-key, and Markdown symbols at runtime; it never downloads plugins.
Use `NVIM_NERD_FONT=0` or omit the variable to return to plain symbols.

The current directory is mounted at `/workspace`, and all arguments are forwarded to
Neovim inside the frozen container. Absolute paths below the current directory are
translated to `/workspace`; absolute paths outside it fail with an explanation instead of
opening an unrelated empty buffer. Files outside the current directory are intentionally
not exposed to the container.

Running `nvim` without arguments starts with an empty buffer and `/workspace` as the
current directory. It does not open `/workspace` as a directory buffer. Pass `.` explicitly
when directory browsing is wanted.

Neovim's ShaDa is stored in the single `nvim-workbench-shada` Docker volume. Consequently,
ddu's `file_old` source (`sm`) retains one global recent-file history across projects,
container removal, and image rebuilds. Because every project appears below `/workspace`,
same relative paths in different projects may collide by design. The shared ShaDa also
retains Neovim marks, registers, and search history, with old-file marks capped at 1000
entries. Inspect the volume with:

```bash
docker volume inspect nvim-workbench-shada
```

This volume survives container removal and image rebuilds, but it is mutable state and is
not included in `scripts/export.sh` image archives. Back it up separately before
resetting Docker Desktop or moving to another Mac if the history must be retained.

When launched through SSH, the wrapper passes `NVIM_NOTTYFAST=1` to Neovim. This disables
startup terminal queries that some iPad SSH clients do not answer and avoids the harmless
E1568 background-color DSR timeout warning.

The OSC 52 clipboard provider is configured explicitly. Neovim's separate OSC 52
XTGETTCAP auto-detection is disabled because Prompt 3 can render the unsupported `Ms`
query payload (`+q4D73`) over the first line. This is screen corruption only, not a buffer
or file modification; normal OSC 52 copy remains enabled.

For a Git working tree, `dev` creates one reusable zellij session with four tabs:

```text
Neovim  Dockerized frozen editor
Codex   Host-side Codex CLI
Git     lazygit when installed, otherwise a Git-aware host shell
Test    Host-side test shell
```

Outside a Git working tree, `dev` opens only the Dockerized `Neovim` tab. Codex, Git,
and Test tabs are omitted because there is no repository context for them.

Running `dev` again attaches to the existing project session instead of creating duplicate
tabs. If the frozen image is missing, it is built automatically. Use `dev --rebuild` for an
intentional rebuild, or `DEV_TEST_COMMAND='uv run pytest' dev` to execute a project-specific
test command when the Test tab opens.

Generated session names are capped at 21 characters so the Zellij IPC socket remains below
the macOS Unix socket path limit even when `$TMPDIR` is long.

The top bar shows the tabs available for the selected workspace. The bottom status bar
shows the keyboard actions available in the current Zellij mode, so the hints
change after entering Pane or Tab mode. With Zellij's default key preset, useful starting
points are `Ctrl-t` for Tab mode, `Ctrl-p` for Pane mode, and `Ctrl-o d` to detach.

The lower-level editor-only command remains available:

```bash
./scripts/run.sh ~/work/my-project
```

With no argument, the current directory is mounted:

```bash
cd ~/work/my-project
/path/to/nvim-workbench/scripts/run.sh
```

Only that directory is shared at `/workspace`. Saving in Neovim immediately changes the
macOS file. The image never mounts the macOS home directory, SSH keys, or Docker socket.

Useful mappings:

| Mapping | Action |
| --- | --- |
| `sN` | Find files from the current buffer directory |
| `s;` / `sm` | Find buffers / buffers and recent files |
| `s/` / `sg` | Search lines / project text |
| `sn` | Open the ddu file browser |
| `<leader>f` | Format buffer |
| `gd` / `gr` | Definition / references |
| `<leader>rn` | LSP rename |
| `gcc` / `gc{motion}` | Toggle comments (built into Neovim) |
| `ys` / `ds` / `cs` | Add, delete, or change surroundings |
| `*` / `#` | Search without moving the cursor |
| `jj` (insert mode) | Return to normal mode |
| `"+y` | Copy through OSC 52 |

`:DppInfo` reports the frozen dpp state and Denops status. Mutating commands such as
`DppInstall`, `DppUpdate`, and `DppMakeState` are intentionally build-time-only; rebuild a
candidate image to change plugins.

Normal terminal paste is the most portable paste path. OSC 52 paste queries are enabled,
but some terminals intentionally block them.

## zellij / SSH usage

A practical split keeps editor and host tools separate. The `dev` command creates this
layout automatically:

```text
zellij
├── edit   ./scripts/run.sh ~/work/my-project
├── codex  codex
├── test   uv run pytest
└── git    lazygit
```

For iPad access, SSH into the Mac, attach to zellij, and run the same command. Copy flows
from Neovim through Docker, zellij, and SSH to the terminal displaying the session. Each
layer must allow OSC 52.

## Preserve the known-working image

```bash
./scripts/export.sh
```

This writes the compressed image, its SHA-256, image metadata, and a version manifest
under `artifacts/`. Store those files in durable backup storage. Restore later with:

```bash
./scripts/import.sh artifacts/nvim-workbench-2026-07-stable.tar.gz
./scripts/smoke-test.sh
```

The exported image—not a future rebuild—is the authoritative frozen artifact. Package
repositories and upstream source hosts can change or disappear even when the recipe is
pinned.

See [architecture](docs/architecture.md) for the trust boundary and
[maintenance](docs/maintenance.md) for safe candidate-to-stable updates. The
[Windows 11 import notes](docs/windows11-import.md) and the machine-readable
`config/nvim/dpp/selection.toml` record every plugin as adopted, rejected, or deferred.
Deferred entries stay available for a later, pinned promotion into the frozen image.
