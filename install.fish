#!/usr/bin/env -S fish --no-config

set script_dir (realpath (dirname (status --current-filename)))
set config_dir "$HOME/.config"
if set -q XDG_CONFIG_HOME; and test -n "$XDG_CONFIG_HOME"
    set config_dir "$XDG_CONFIG_HOME"
end

function link_config --argument-names source target
    if not test -e "$source"
        printf 'Missing config: %s\n' "$source" >&2
        return 1
    end

    if test -L "$target"; and test (readlink "$target") = "$source"
        return 0
    end

    mkdir -p (dirname "$target"); or return 1
    if test -e "$target"; or test -L "$target"
        set -l backup "$target.backup."(date +%Y%m%d-%H%M%S-%N)
        mv -T -- "$target" "$backup"; or return 1
        printf 'Backed up existing config to %s\n' "$backup"
    end

    ln -sT -- "$source" "$target"; or return 1
    printf '%s -> %s\n' "$target" "$source"
end

link_config "$script_dir/zellij/config.kdl" "$config_dir/zellij/config.kdl"; or exit 1
link_config "$script_dir/nvim" "$config_dir/nvim"; or exit 1
link_config "$script_dir/fish/config.fish" "$config_dir/fish/config.fish"; or exit 1
