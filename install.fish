#!/usr/bin/env fish

set SCRIPT_DIR (realpath (dirname (status --current-filename)))
set SOURCE "$SCRIPT_DIR/zellij/config.kdl"
set TARGET_DIR "$HOME/.config/zellij"
set TARGET "$TARGET_DIR/config.kdl"

if not test -f "$SOURCE"
    echo "Missing config: $SOURCE"
    exit 1
end

mkdir -p "$TARGET_DIR"

if test -e "$TARGET"; or test -L "$TARGET"
    set BACKUP "$TARGET.backup."(date +%Y%m%d-%H%M%S)
    mv "$TARGET" "$BACKUP"
    echo "Backed up existing config to: $BACKUP"
end

ln -s "$SOURCE" "$TARGET"
echo "Installed Zellij config:"
echo "$TARGET -> $SOURCE"
