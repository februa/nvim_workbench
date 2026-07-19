# Windows 11 configuration import

The previous `neovim-windows11` configuration treats the Shougo ecosystem as its core.
This workbench retains that identity while adapting lifecycle operations to a frozen,
offline container. The machine-readable decision ledger is
`config/nvim/dpp/selection.toml` and deliberately stays ordered as adopted, rejected,
then deferred.

## 採用

| Area | Result |
| --- | --- |
| dpp core | `dpp.vim`, `denops.vim`, installer/lazy/TOML extensions, and Git protocol are pinned and used to generate state during the image build. |
| ddu | The ff UI, filer UI, file/buffer/recent/line/rg sources, file kind, substring matcher, and runtime-selected plain/icon filename columns are retained. |
| Editing | `nvim-autopairs`, `nvim-surround`, and `vim-asterisk` are retained. |
| Feedback and help | `fidget.nvim` and `vimdoc-ja` are retained. |
| Display | Wisteria, lualine, which-key, Markdown rendering, and web-devicons are retained; Nerd Font symbols are an explicit runtime option. |
| Existing workbench | Tree-sitter, native LSP completion, conform.nvim, and gitsigns.nvim remain. |
| Muscle memory | `sN`, `s;`, `sm`, `s/`, `sg`, `sn`, insert-mode `jj`, visual indent retention, and `Y=y$` are retained. |

There are 33 adopted repositories. `core.tsv` pins the six dpp bootstrap repositories;
`plugins.toml` is the active dpp definition and pins the other 27 repositories.

## 不採用

| Area | Decision |
| --- | --- |
| Comment.nvim | Neovim 0.12 built-in `gc` operators replace it. |
| Mason | Language servers and tools are pinned and baked into the image. Runtime installation conflicts with the frozen boundary. |
| nvim-cmp and VimSnip | Neovim 0.12 native LSP completion replaces this stack. |
| vim-fugitive and toggleterm | Git, tests, project runtimes, and shells intentionally stay in host-side Zellij tabs. |
| Avante, plenary, and nui | Runtime networking and credentials belong outside the editor container; the host-side Codex tab covers this role. |
| zk-nvim | It requires an external binary and notebook storage outside the deliberately narrow project mount. |
| Telescope | ddu is the single adopted finder interface. |

There are 15 rejected repositories from the old configuration, plus Telescope from
the former workbench configuration. Rejection records an architectural decision; it
is not the queue for likely future additions.

## 見送り

The 10 deferred repositories remain recorded individually in `selection.toml`, with a
reason, so they can be promoted without repeating the original audit. They cover:

- colorschemes and other visual enhancements;
- optional editing/navigation helpers;
- web-oriented Tree-sitter helpers;
- specialized color tooling.

To promote a deferred plugin:

1. Move its `[[deferred]]` entry to the end of the `[[adopted]]` section.
2. Resolve an exact 40-character commit and add the repository to `plugins.toml`.
3. Add the smallest required setup and smoke assertion.
4. Build the candidate image, then run the network-off, read-only smoke test.

The static check fails if the active dpp repository set differs from the adopted set,
or if a repository appears in more than one selection section.

## Frozen lifecycle adaptation

- Deno is downloaded with a verified checksum and copied into the runtime image.
- JSR modules are resolved during the build and the Deno cache is made read-only.
- dpp state and all plugin revisions are generated or installed during the build.
- Git histories are removed after the actual revisions are captured in the image manifest.
- The runtime keeps only the read-only `:DppInfo` command. `DppInstall`, `DppUpdate`,
  `DppMakeState`, `DppClearCache`, and `DppClean` are build-time concerns.
- ddu replaces Telescope, avoiding two competing finder interfaces.
- Both ddu filename columns are frozen into one image. The plain column remains the
  default; `NVIM_NERD_FONT=1` selects the icon column and related display symbols without
  making Nerd Fonts a prerequisite.
