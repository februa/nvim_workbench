# syntax=docker/dockerfile:1.7

# Multi-platform Debian slim index, pinned to an immutable digest.
ARG DEBIAN_IMAGE=debian:stable-slim@sha256:328d16499860ae6cb9b345e2e4cebca08c2a36e4f7278482c7bd1f39d71e5bfd

FROM ${DEBIAN_IMAGE} AS builder

ARG TARGETARCH
ARG NEOVIM_VERSION=0.12.4
ARG TREE_SITTER_VERSION=0.26.11
ARG LUA_LS_VERSION=3.18.2
ARG PYRIGHT_VERSION=1.1.411
ARG RUFF_VERSION=0.15.22
ARG STYLUA_VERSION=2.5.2

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/home/nvim \
    XDG_CONFIG_HOME=/home/nvim/.config \
    XDG_DATA_HOME=/home/nvim/.local/share \
    XDG_STATE_HOME=/home/nvim/.local/state \
    XDG_CACHE_HOME=/home/nvim/.cache \
    NVIM_CONTAINER=1

# These packages are needed only while assembling the frozen runtime.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        curl \
        git \
        gzip \
        nodejs \
        npm \
        tar \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Official Neovim release tarballs, selected by BuildKit's TARGETARCH.
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) archive_arch=x86_64; checksum=012bf3fcac5ade43914df3f174668bf64d05e049a4f032a388c027b1ebd78628 ;; \
      arm64) archive_arch=arm64; checksum=ceb7e88c6b681f0515d135dcdfad54f5eb4373b25ce6172197cd9a69c758063f ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    url="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-${archive_arch}.tar.gz"; \
    curl --fail --location --retry 3 --output /tmp/nvim.tar.gz "${url}"; \
    echo "${checksum}  /tmp/nvim.tar.gz" | sha256sum --check --strict; \
    tar -xzf /tmp/nvim.tar.gz -C /opt; \
    mv "/opt/nvim-linux-${archive_arch}" /opt/nvim; \
    ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim; \
    rm /tmp/nvim.tar.gz

# Tree-sitter CLI is a build-only dependency used to compile frozen parsers.
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) archive_arch=x64; checksum=ff1b7f9863f2faafd78dc0e66d902ee85b37f709b314b22c009f51caf233eebd ;; \
      arm64) archive_arch=arm64; checksum=db28509fe6db8902f9d14c43c486858c7486b42c3a96b30e811e73f105762336 ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    url="https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-cli-linux-${archive_arch}.zip"; \
    curl --fail --location --retry 3 --output /tmp/tree-sitter.zip "${url}"; \
    echo "${checksum}  /tmp/tree-sitter.zip" | sha256sum --check --strict; \
    unzip -q /tmp/tree-sitter.zip -d /usr/local/bin; \
    chmod 0755 /usr/local/bin/tree-sitter; \
    rm /tmp/tree-sitter.zip

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) archive_arch=x64; checksum=ca71415dd19f19e30aaa35a4915aefca9fdb5fec31b98331cc3d77f778d539c5 ;; \
      arm64) archive_arch=arm64; checksum=273af33f26f4a1143f27c96d9f9e1188aba619c71e0807042134f66b4bd27f24 ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    url="https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LS_VERSION}/lua-language-server-${LUA_LS_VERSION}-linux-${archive_arch}.tar.gz"; \
    curl --fail --location --retry 3 --output /tmp/lua-ls.tar.gz "${url}"; \
    echo "${checksum}  /tmp/lua-ls.tar.gz" | sha256sum --check --strict; \
    mkdir -p /opt/lua-language-server; \
    tar -xzf /tmp/lua-ls.tar.gz -C /opt/lua-language-server; \
    rm /tmp/lua-ls.tar.gz

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) archive_arch=x86_64; checksum=d535a4be6504146e757eff67b992f11a293a7a108be22e2a5898b32c32565996 ;; \
      arm64) archive_arch=aarch64; checksum=54ec426d839d7cea1096e9ea1c5486fd2f3df62ee6cfd71dc090b18f99bebd90 ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    url="https://github.com/astral-sh/ruff/releases/download/${RUFF_VERSION}/ruff-${archive_arch}-unknown-linux-gnu.tar.gz"; \
    curl --fail --location --retry 3 --output /tmp/ruff.tar.gz "${url}"; \
    echo "${checksum}  /tmp/ruff.tar.gz" | sha256sum --check --strict; \
    tar -xzf /tmp/ruff.tar.gz -C /tmp; \
    install -m 0755 "/tmp/ruff-${archive_arch}-unknown-linux-gnu/ruff" /usr/local/bin/ruff; \
    rm -rf /tmp/ruff*

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) archive_arch=x86_64; checksum=bcb0d855e91f102f28a370e850f8566b3b44b79e6274d806ea5246837c0fd5ab ;; \
      arm64) archive_arch=aarch64; checksum=0ef2ebf0b7e5a652b65c4cb96c6d9ffb3981a98547de3c764465bbf54a8d761a ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    url="https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VERSION}/stylua-linux-${archive_arch}.zip"; \
    curl --fail --location --retry 3 --output /tmp/stylua.zip "${url}"; \
    echo "${checksum}  /tmp/stylua.zip" | sha256sum --check --strict; \
    unzip -q /tmp/stylua.zip -d /usr/local/bin; \
    chmod 0755 /usr/local/bin/stylua; \
    rm /tmp/stylua.zip

RUN npm install --global --omit=dev "pyright@${PYRIGHT_VERSION}" \
    && npm cache clean --force

RUN mkdir -p \
        /home/nvim/.config/nvim \
        /home/nvim/.local/share/nvim/lazy \
        /home/nvim/.local/state/nvim \
        /home/nvim/.cache/nvim \
        /opt/workbench/scripts \
        /opt/workbench/tests/fixtures \
        /workspace

COPY config/nvim/ /home/nvim/.config/nvim/
COPY tests/ /opt/workbench/tests/
COPY scripts/container-smoke-test /opt/workbench/scripts/container-smoke-test
COPY scripts/capture-manifest /opt/workbench/scripts/capture-manifest

# Restore pinned plugins, compile parsers, record commits, and discard Git histories.
RUN git clone --filter=blob:none https://github.com/folke/lazy.nvim.git /home/nvim/.local/share/nvim/lazy/lazy.nvim \
    && git -C /home/nvim/.local/share/nvim/lazy/lazy.nvim checkout 85c7ff3711b730b4030d03144f6db6375044ae82 \
    && NVIM_IMAGE_BUILD=1 nvim --headless "+Lazy! restore" "+qa" \
    && NVIM_IMAGE_BUILD=1 nvim --headless "+luafile /opt/workbench/tests/install-parsers.lua" \
    && tree-sitter --version | awk '{ print $2 }' > /opt/workbench/tree-sitter-version.txt \
    && for plugin in /home/nvim/.local/share/nvim/lazy/*; do \
         printf '%s\t%s\n' "$(basename "${plugin}")" "$(git -C "${plugin}" rev-parse HEAD)"; \
       done > /opt/workbench/plugin-manifest.txt \
    && find /home/nvim/.local/share/nvim/lazy -type d -name .git -prune -exec rm -rf {} +


FROM ${DEBIAN_IMAGE} AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/home/nvim \
    XDG_CONFIG_HOME=/home/nvim/.config \
    XDG_DATA_HOME=/home/nvim/.local/share \
    XDG_STATE_HOME=/home/nvim/.local/state \
    XDG_CACHE_HOME=/home/nvim/.cache \
    NVIM_CONTAINER=1

# Runtime-only OS dependencies. Build tools, curl, npm, and archive tools stay behind.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        clangd \
        fd-find \
        git \
        nodejs \
        passwd \
        ripgrep \
        shellcheck \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd

RUN set -eux; \
    existing_user="$(getent passwd 1000 | cut -d: -f1 || true)"; \
    if [ -n "${existing_user}" ]; then \
        existing_group="$(id -gn "${existing_user}")"; \
        usermod --login nvim --home /home/nvim --shell /bin/bash "${existing_user}"; \
        if [ "${existing_group}" != nvim ]; then \
            groupmod --new-name nvim "${existing_group}"; \
        fi; \
    else \
        useradd --create-home --shell /bin/bash --uid 1000 nvim; \
    fi; \
    mkdir -p \
        /home/nvim/.cache/nvim \
        /home/nvim/.local/state/nvim \
        /workspace; \
    chown -R nvim:nvim /home/nvim/.cache /home/nvim/.local/state /workspace

COPY --from=builder /opt/nvim/ /opt/nvim/
COPY --from=builder /opt/lua-language-server/ /opt/lua-language-server/
COPY --from=builder /usr/local/bin/ruff /usr/local/bin/ruff
COPY --from=builder /usr/local/bin/stylua /usr/local/bin/stylua
COPY --from=builder /usr/local/lib/node_modules/pyright/ /usr/local/lib/node_modules/pyright/
COPY --from=builder /home/nvim/.config/nvim/ /home/nvim/.config/nvim/
COPY --from=builder /home/nvim/.local/share/nvim/ /home/nvim/.local/share/nvim/
COPY --from=builder /opt/workbench/ /opt/workbench/

RUN ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim \
    && ln -s /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server \
    && ln -s ../lib/node_modules/pyright/index.js /usr/local/bin/pyright \
    && ln -s ../lib/node_modules/pyright/langserver.index.js /usr/local/bin/pyright-langserver \
    && chown -R root:root /home/nvim/.config/nvim /home/nvim/.local/share/nvim \
    && chmod -R a-w /home/nvim/.config/nvim /home/nvim/.local/share/nvim

USER nvim
RUN /opt/workbench/scripts/container-smoke-test

USER root
RUN /opt/workbench/scripts/capture-manifest /opt/workbench/manifest.txt

LABEL org.opencontainers.image.title="nvim-workbench" \
      org.opencontainers.image.description="Frozen Neovim editor environment for macOS-hosted projects" \
      org.opencontainers.image.version="2026-07" \
      org.opencontainers.image.source="local"

USER nvim
WORKDIR /workspace
ENTRYPOINT ["nvim"]
CMD ["."]
