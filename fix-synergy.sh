#!/usr/bin/env bash
# Recover the broken Synergy 3 package, reinstall it, and lock in the fixes that
# stop it (and other Electron apps) from crashing in the i3/Xorg session.
# Usage:  bash ~/projects/dots/fix-synergy.sh [/path/to/synergy-*.deb]
# Needs sudo (will prompt). Safe to re-run.
set -u

# --- 1. locate the .deb -------------------------------------------------------
DEB="${1:-}"
if [ -z "$DEB" ]; then
  DEB=$(ls -t "$HOME"/Downloads/synergy-*.deb "$HOME"/synergy-*.deb ./synergy-*.deb 2>/dev/null | head -1)
fi
if [ -z "$DEB" ] || [ ! -f "$DEB" ]; then
  echo "!! Could not find a synergy-*.deb. Pass its path:"
  echo "   bash ~/projects/dots/fix-synergy.sh ~/Downloads/synergy-3.6.3-linux-noble-x86_64.deb"
  exit 1
fi
echo "==> Using package: $DEB"

# --- 2. stop anything holding the old install --------------------------------
echo "==> Stopping synergy processes/services"
pkill -x synergy 2>/dev/null || true
sudo systemctl stop synergy.service 2>/dev/null || true
systemctl --user stop synergy.service 2>/dev/null || true

# --- 3. clear the broken half-removed package --------------------------------
# The old package's prerm launches the binary, which crashes on Wayland and makes
# dpkg abort. Remove the maintainer scripts so purge can't be blocked by them.
echo "==> Removing broken synergy package"
sudo rm -f /var/lib/dpkg/info/synergy.prerm /var/lib/dpkg/info/synergy.postrm
sudo dpkg --purge --force-all synergy 2>/dev/null || true

# --- 4. reinstall ------------------------------------------------------------
echo "==> Reinstalling synergy"
if ! sudo apt install -y "$DEB"; then
  echo "   apt path failed; forcing files in and skipping maintainer scripts"
  sudo dpkg -i --force-all "$DEB" || true
  sudo apt-get -f install -y || true
fi

# --- 5. put the binary on PATH -----------------------------------------------
if [ -x /opt/Synergy/synergy ] && [ ! -e /usr/local/bin/synergy ]; then
  sudo ln -sfn /opt/Synergy/synergy /usr/local/bin/synergy
  echo "==> Linked /usr/local/bin/synergy"
fi

# --- 6. disable the greeter "Login service" (crashes on Wayland, just noise) --
echo "==> Disabling greeter login service (optional, stops boot errors)"
sudo systemctl disable --now synergy.service 2>/dev/null || true

# --- 7. ensure the Electron-on-X11 session fix exists ------------------------
XSR="$HOME/.xsessionrc"
if ! grep -q "ELECTRON_OZONE_PLATFORM_HINT" "$XSR" 2>/dev/null; then
  echo "==> Writing $XSR (forces X11 backend for Electron apps)"
  cat > "$XSR" <<'EOF'
# GDM mislabels the i3/Xorg session as wayland; force X11 so Electron apps
# (Synergy, Slack, Telegram, Todoist, Obsidian, VS Code) don't crash on launch.
export ELECTRON_OZONE_PLATFORM_HINT=x11
export XDG_SESSION_TYPE=x11
EOF
fi

echo ""
echo "==================================================================="
echo "DONE. Now:"
echo "  1. Log OUT and back into i3  (so ~/.xsessionrc takes effect)."
echo "  2. Synergy will autostart. To test immediately without re-login:"
echo "       /opt/Synergy/synergy --ozone-platform=x11 &"
echo "  3. Open Synergy once and configure your server + screen layout."
echo "==================================================================="
