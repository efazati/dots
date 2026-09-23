#!/usr/bin/env bash
# GNOME (Wayland) take on the i3 bindings in ../i3/config.
# Safe to re-run. Log out and back in once after the first run so
# gnome-shell loads ddterm.
set -euo pipefail

WM=org.gnome.desktop.wm.keybindings
SHELL_KB=org.gnome.shell.keybindings
MEDIA=org.gnome.settings-daemon.plugins.media-keys
CUSTOM_PATH=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings

# --- Scratchpad terminal: ddterm on Super+x (i3: $mod+x scratchpad_urxvt) ---
DDTERM=ddterm@amezin.github.com
EXT_DIR=$HOME/.local/share/gnome-shell/extensions/$DDTERM
if [ ! -d "$EXT_DIR" ]; then
  shell_ver=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/ddterm.zip" \
    "https://extensions.gnome.org/download-extension/$DDTERM.shell-extension.zip?shell_version=$shell_ver"
  gnome-extensions install --force "$tmp/ddterm.zip"
  rm -rf "$tmp"
fi

# gnome-shell only sees a new extension after a relogin, so enable it
# through the setting it reads at startup rather than gnome-extensions.
enabled=$(gsettings get org.gnome.shell enabled-extensions)
if [[ $enabled != *"$DDTERM"* ]]; then
  gsettings set org.gnome.shell enabled-extensions \
    "$(python3 -c "import ast,sys;l=ast.literal_eval(sys.argv[1].replace('@as ',''));l.append(sys.argv[2]);print(l)" "$enabled" "$DDTERM")"
fi

schemas=$(mktemp -d)
glib-compile-schemas --targetdir="$schemas" "$EXT_DIR/schemas"
dd() { gsettings --schemadir "$schemas" set org.gnome.shell.extensions.ddterm "$@"; }
dd ddterm-toggle-hotkey "['<Super>x']"
dd window-size 0.85
dd window-position top
dd window-monitor current
dd hide-when-focus-lost false
dd window-above true
dd window-skip-taskbar true
# ddterm disables its copy action while nothing is selected, so Ctrl+C
# still reaches the shell as ^C unless there is a selection.
dd shortcut-terminal-copy "['<Ctrl>c', '<Ctrl><Shift>c', 'Copy']"
dd shortcut-terminal-paste "['<Ctrl>v', '<Ctrl><Shift>v', 'Paste']"
dd use-system-font false
dd custom-font "'Monaco 12'"
rm -rf "$schemas"

# --- Terminal fonts: same faces as urxvt under i3 (../Xdefaults) ---
# Monaco for Latin, Vazirmatn NL for Persian via ../fontconfig. ddterm has
# no line spacing setting; Ptyxis does, matching URxvt.lineSpace.
DOTS=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$HOME/.fonts" "$HOME/.config/fontconfig/conf.d"
cp "$DOTS"/fonts/monaco.ttf "$DOTS"/fonts/Vazirmatn-NL-*.ttf "$HOME/.fonts/"
ln -sf "$DOTS/fontconfig/conf.d/99-persian.conf" "$HOME/.config/fontconfig/conf.d/"
fc-cache -f
gsettings set org.gnome.Ptyxis use-system-font false
gsettings set org.gnome.Ptyxis font-name 'Monaco 12'
for uuid in $(gsettings get org.gnome.Ptyxis profile-uuids | tr -d "[]',"); do
  gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/$uuid/" cell-height-scale 1.2
done

# --- Autostart at login (i3: exec code) ---
mkdir -p "$HOME/.config/autostart"
cat >"$HOME/.config/autostart/code.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Visual Studio Code
Exec=code
X-GNOME-Autostart-enabled=true
EOF

# --- Synergy: survive logout/login ---
# On relogin synergy-service can see the previous session's instance, log
# "existing service detected" and exit 0, which Restart=on-failure ignores.
# Restart on clean exit too; the start limit stops a real duplicate looping.
if [ -f /etc/systemd/user/synergy.service ]; then
  mkdir -p "$HOME/.config/systemd/user/synergy.service.d"
  cat >"$HOME/.config/systemd/user/synergy.service.d/restart.conf" <<'EOF'
[Unit]
StartLimitIntervalSec=120
StartLimitBurst=10

[Service]
Restart=always
RestartSec=3
EOF
  systemctl --user daemon-reload
fi

# --- Workspaces: fixed 10, Super+N / Super+Shift+N ---
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 10
# Ubuntu dock and gnome-shell both claim Super+N for "launch app N".
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false 2>/dev/null || true
for n in 1 2 3 4 5 6 7 8 9 10; do
  key=$((n % 10))
  gsettings set $WM switch-to-workspace-$n "['<Super>$key']"
  gsettings set $WM move-to-workspace-$n "['<Super><Shift>$key']"
  [ "$n" -le 9 ] && gsettings set $SHELL_KB switch-to-application-$n "[]"
done
# i3: $mod+Ctrl+Left/Right = workspace prev/next. Frees Super+PageUp/Down.
gsettings set $WM switch-to-workspace-left "['<Super><Control>Left', '<Control><Alt>Left']"
gsettings set $WM switch-to-workspace-right "['<Super><Control>Right', '<Control><Alt>Right']"

# --- Windows ---
gsettings set $WM close "['<Super>q', '<Alt>F4']"
gsettings set $WM toggle-fullscreen "['<Super><Control>x']"
gsettings set $WM toggle-on-all-workspaces "['<Super><Shift>s']"

# --- Launcher / screenshot / session ---
# Single input source here, so Super+space is free for the app grid (i3: rofi drun).
gsettings set $WM switch-input-source "[]"
gsettings set $WM switch-input-source-backward "[]"
gsettings set $SHELL_KB toggle-application-view "['<Super>space', '<Super>a']"
gsettings set $SHELL_KB show-screenshot-ui "['Print', '<Super>b']"
gsettings set $SHELL_KB toggle-quick-settings "[]"
gsettings set $MEDIA screensaver "['<Super>l', '<Super><Control>q']"
gsettings set $MEDIA logout "['<Super><Control>l']"
gsettings set $MEDIA volume-up "['<Super>Prior']"
gsettings set $MEDIA volume-down "['<Super>Next']"

# --- Custom launchers (owned by this script: dots-N entries) ---
bindings=(
  "terminal|<Super>Return|ptyxis --new-window"
  "firefox tab|<Super>t|firefox --new-tab --url google.com"
  "slack|<Super>s|slack"
  "code|<Super><Shift>F3|code"
  "pavucontrol|<Super><Control>p|pavucontrol"
)

existing=$(gsettings get $MEDIA custom-keybindings)
paths=$(python3 -c "import ast,sys;l=ast.literal_eval(sys.argv[1].replace('@as ',''));print(' '.join(p for p in l if '/dots-' not in p))" "$existing")
i=0
for b in "${bindings[@]}"; do
  IFS='|' read -r name key cmd <<<"$b"
  p=$CUSTOM_PATH/dots-$i/
  schema=org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$p
  gsettings set "$schema" name "$name"
  gsettings set "$schema" binding "$key"
  gsettings set "$schema" command "$cmd"
  paths="$paths $p"
  i=$((i + 1))
done
gsettings set $MEDIA custom-keybindings \
  "$(python3 -c "import sys;print([p for p in sys.argv[1:]])" $paths)"

echo "Done. Log out and back in once so gnome-shell loads ddterm (Super+x)."
