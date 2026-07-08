#!/usr/bin/env bash
# Ubuntu 26.04 setup for efazati/dots — i3 + zsh + warp workflow.
# Non-sudo parts (repo clone, symlinks, warp config, Monaco font) are already
# handled; this script does the parts that need root + the oh-my-zsh install.
# Safe to re-run (idempotent-ish). Run with:  bash ~/projects/dots/setup-ubuntu2604.sh
set -u
DOTS="$HOME/projects/dots"

echo "==> apt update"
sudo apt-get update -y

# Install packages one-by-one so a renamed/missing name on 26.04 doesn't abort the rest.
PKGS=(
  # window manager + session
  i3 i3lock xautolock feh rofi polybar dunst suckless-tools lxappearance arandr
  # Xorg input drivers — Ubuntu 26.04 is Wayland-first and ships without these,
  # so an Xorg session (i3) has NO working mouse/keyboard until they're installed.
  xserver-xorg-input-all xserver-xorg-input-libinput xinit
  # terminal-adjacent / shell (zsh deps: oh-my-zsh installed below; fzf/jq used by zshrc)
  zsh git curl vim tmux bat autojump htop fzf jq
  zsh-autosuggestions zsh-syntax-highlighting
  # tray / desktop helpers used by the i3 config
  network-manager-gnome blueman bluez xfce4-clipman xfce4-screenshooter flameshot
  gromit-mpx xclip xdotool pavucontrol
  # file manager, docs, fonts
  thunar evince zenity zip hwinfo psensor
  fonts-font-awesome fonts-noto-color-emoji fonts-noto-core flatpak
  # networking / vpn / remote / cloud
  wireguard wireguard-tools remmina tigervnc-viewer x11vnc samba samba-vfs-modules
  awscli vagrant
)
FAILED=()
for p in "${PKGS[@]}"; do
  if ! sudo apt-get install -y "$p" >/dev/null 2>&1; then
    echo "   !! could not install: $p"
    FAILED+=("$p")
  else
    echo "   ok: $p"
  fi
done

# --- extra CLI tools not in the apt list: GitHub CLI, kubectl, helm ---
echo "==> GitHub CLI (gh) — official apt repo"
if ! command -v gh >/dev/null; then
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -y && sudo apt-get install -y gh
fi

echo "==> kubectl + helm (snap --classic: no version-pinned repo URLs, auto-updates)"
command -v kubectl >/dev/null || sudo snap install kubectl --classic
command -v helm    >/dev/null || sudo snap install helm --classic

echo "==> default shell -> zsh"
sudo chsh "$USER" -s /bin/zsh

echo "==> Monaco font"
mkdir -p "$HOME/.fonts"
cp -f "$DOTS/fonts/monaco.ttf" "$HOME/.fonts/" 2>/dev/null || true
fc-cache -f "$HOME/.fonts" >/dev/null 2>&1 || true

echo "==> oh-my-zsh (unattended, keep our .zshrc symlink)"
export ZSH="$HOME/.oh-my-zsh"
if [ ! -d "$ZSH" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
# .zshrc is a symlink to the repo — the installer keeps it with KEEP_ZSHRC=yes.
[ -L "$HOME/.zshrc" ] || ln -sfn "$DOTS/zshrc" "$HOME/.zshrc"

echo "==> custom zsh plugins (referenced by zshrc: fast-syntax-highlighting, kube-ps1)"
CUSTOM="$ZSH/custom/plugins"
mkdir -p "$CUSTOM"
clone_plugin() { [ -d "$CUSTOM/$1" ] || git clone --depth 1 "$2" "$CUSTOM/$1"; }
clone_plugin fast-syntax-highlighting https://github.com/zdharma-continuum/fast-syntax-highlighting.git
clone_plugin kube-ps1                  https://github.com/jonmosco/kube-ps1.git
clone_plugin zsh-autosuggestions       https://github.com/zsh-users/zsh-autosuggestions.git
clone_plugin zsh-syntax-highlighting   https://github.com/zsh-users/zsh-syntax-highlighting.git

# Synergy 3 lives at /opt/Synergy/synergy (installed manually from symless.com).
# Put it on PATH so `synergy` works in a shell, matching muscle memory.
if [ -x /opt/Synergy/synergy ] && [ ! -e /usr/local/bin/synergy ]; then
  echo "==> symlink /opt/Synergy/synergy -> /usr/local/bin/synergy"
  sudo ln -sfn /opt/Synergy/synergy /usr/local/bin/synergy
fi

echo ""
echo "==================================================================="
echo "DONE. Log out and pick the 'i3' session (gear icon on the GDM login"
echo "screen) — that runs Xorg, which is required for i3 AND makes synergy"
echo "clipboard sharing work again (Wayland was the cause)."
echo ""
[ ${#FAILED[@]} -gt 0 ] && echo "Packages that failed (install manually if needed): ${FAILED[*]}"
echo "Note: Synergy itself is a separate .deb from symless.com — reinstall"
echo "that as before; the clipboard fix is the Xorg session, not the pkg."
echo "==================================================================="
