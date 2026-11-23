#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
nvim_version=0.12.4
zellij_version=0.44.3
tree_sitter_version=0.26.12

if [[ $(uname -s) != Linux || $(uname -m) != x86_64 ]]; then
    printf 'This installer requires Debian or Ubuntu on Linux x86_64.\n' >&2
    exit 1
fi

packages=()
for package in build-essential ca-certificates curl fish git ripgrep unzip; do
    if [[ $(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null) != installed ]]; then
        packages+=("$package")
    fi
done
if ((${#packages[@]})); then
    apt=(apt-get)
    if ((EUID != 0)); then
        apt=(sudo apt-get)
    fi
    "${apt[@]}" update
    "${apt[@]}" install -y "${packages[@]}"
fi

bin_dir="$HOME/.local/bin"
opt_dir="$HOME/.local/opt"
mkdir -p "$bin_dir" "$opt_dir"
tmp_dir="$(mktemp -d "$opt_dir/.install.XXXXXX")"
trap 'rm -rf -- "$tmp_dir"' EXIT

nvim_dir="$opt_dir/nvim-$nvim_version"
if [[ ! -x "$nvim_dir/bin/nvim" ]]; then
    curl -fsSL "https://github.com/neovim/neovim/releases/download/v$nvim_version/nvim-linux-x86_64.tar.gz" \
        -o "$tmp_dir/nvim.tar.gz"
    tar -xzf "$tmp_dir/nvim.tar.gz" -C "$tmp_dir"
    mv -T -- "$tmp_dir/nvim-linux-x86_64" "$nvim_dir"
fi
ln -sfnT -- "$nvim_dir/bin/nvim" "$bin_dir/nvim"

zellij_bin="$opt_dir/zellij-$zellij_version"
if [[ ! -x "$zellij_bin" ]]; then
    curl -fsSL "https://github.com/zellij-org/zellij/releases/download/v$zellij_version/zellij-x86_64-unknown-linux-musl.tar.gz" \
        -o "$tmp_dir/zellij.tar.gz"
    tar -xzf "$tmp_dir/zellij.tar.gz" -C "$tmp_dir" zellij
    install -m 755 "$tmp_dir/zellij" "$zellij_bin"
fi
ln -sfnT -- "$zellij_bin" "$bin_dir/zellij"

tree_sitter_bin="$opt_dir/tree-sitter-$tree_sitter_version"
if [[ ! -x "$tree_sitter_bin" ]]; then
    curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v$tree_sitter_version/tree-sitter-linux-x64.gz" \
        -o "$tmp_dir/tree-sitter.gz"
    gzip -dc "$tmp_dir/tree-sitter.gz" > "$tmp_dir/tree-sitter"
    install -m 755 "$tmp_dir/tree-sitter" "$tree_sitter_bin"
fi
ln -sfnT -- "$tree_sitter_bin" "$bin_dir/tree-sitter"

curl -fsSL https://chatgpt.com/codex/install.sh \
    | CODEX_NON_INTERACTIVE=1 CODEX_INSTALL_DIR="$bin_dir" sh

export PATH="$bin_dir:$PATH"
"$repo_dir/install.fish"
nvim_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
mkdir -p "$nvim_state_dir"
cp -- "$repo_dir/nvim/lazy-lock.json" "$nvim_state_dir/lazy-lock.json"
NVIM_APPNAME=nvim nvim --headless +qa
# Lazy can update the local lock while discovering plugins on the first launch.
cp -- "$repo_dir/nvim/lazy-lock.json" "$nvim_state_dir/lazy-lock.json"
NVIM_APPNAME=nvim nvim --headless '+Lazy! restore' +qa
