#!/usr/bin/env bash
# Go back to the single-screen layout.
#
# The layout itself is machine-local: arandr writes it to ~/.screenlayout, and
# what "default" means differs per machine, so it does not belong in the repo.
# What does belong here is a stable path for the keybinding to call, because the
# binding used to point at ~/bin/screen/default.sh, which existed only if run.sh
# had made that one symlink, on that one machine, under that one name.
set -u

layout="${SCREEN_DEFAULT_LAYOUT:-$HOME/.screenlayout/1mon.sh}"

if [ ! -x "$layout" ]; then
    # Said out loud rather than failing silently: a screen binding that does
    # nothing looks like a broken keyboard, and you go looking in i3 first.
    notify-send "Screen layout" "No layout at $layout. Save one with arandr, or set SCREEN_DEFAULT_LAYOUT." 2>/dev/null
    echo "no executable layout at $layout" >&2
    exit 1
fi

exec bash "$layout"
