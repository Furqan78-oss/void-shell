#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Starting void-shell setup..."

# 1. Ensure base-devel and git exist
sudo pacman -Syu --needed --noconfirm base-devel git

# 2. Install official repository packages
echo "==> Installing official pacman packages..."
mapfile -t PACMAN_PKGS < <(grep -vE '^\s*(#|$)' "$DOTFILES_DIR/pkgs/pacman.txt")
if [ ${#PACMAN_PKGS[@]} -gt 0 ]; then
    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
fi

# 3. Install yay AUR helper if missing
if ! command -v yay >/dev/null 2>&1; then
    echo "==> Installing yay AUR helper..."
    TMP_YAY="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$TMP_YAY/yay-bin"
    (cd "$TMP_YAY/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$TMP_YAY"
fi

# 4. Install AUR packages if any are listed
mapfile -t AUR_PKGS < <(grep -vE '^\s*(#|$)' "$DOTFILES_DIR/pkgs/aur.txt")
if [ ${#AUR_PKGS[@]} -gt 0 ]; then
    echo "==> Installing AUR packages..."
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
fi

# 5. Link configs and custom binaries
echo "==> Symlinking configuration files..."
bash "$DOTFILES_DIR/scripts/link.sh"

# 6. Enable NetworkManager and Bluetooth
echo "==> Enabling core services..."
sudo systemctl enable --now NetworkManager bluetooth

# 7. Set Fish as default shell
if command -v fish >/dev/null 2>&1; then
    FISH_PATH="$(command -v fish)"
    if [ "$SHELL" != "$FISH_PATH" ]; then
        echo "==> Setting default shell to fish..."
        chsh -s "$FISH_PATH"
    fi
fi

echo "==> void-shell installation complete!"
