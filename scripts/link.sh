#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
backed_up=false

mkdir -p "$HOME/.config" "$HOME/.local/bin"

link_item() {
    local src="$1"
    local dest="$2"

    # Skip if already linked to the exact target
    if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
        return
    fi

    # Back up existing real file or directory
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/"
        backed_up=true
    fi

    ln -s "$src" "$dest"
    echo "[LINKED] $dest -> $src"
}

# Link everything inside dotfiles/config/ to ~/.config/
for dir in "$DOTFILES_DIR/config"/*; do
    [ -e "$dir" ] || continue
    name="$(basename "$dir")"
    link_item "$dir" "$HOME/.config/$name"
done

# Link executable scripts in dotfiles/shell/bin/ to ~/.local/bin/
if [ -d "$DOTFILES_DIR/shell/bin" ]; then
    for bin in "$DOTFILES_DIR/shell/bin"/*; do
        [ -e "$bin" ] || continue
        chmod +x "$bin"
        link_item "$bin" "$HOME/.local/bin/$(basename "$bin")"
    done
fi

if [ "$backed_up" = true ]; then
    echo "[INFO] Backed up previous configs to: $BACKUP_DIR"
fi
