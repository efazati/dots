#!/usr/bin/env bash
# Lay out whatever DisplayPort monitors are plugged in right now.
#
# auto-ext.py prints an xrandr command rather than running one, so this has to
# run what it printed. It used to do that with a bare `$(python3 ...)`, which
# puts the output in command position: that worked only because the first word
# happened to be `xrandr`, and on a machine with nothing attached the script
# prints "No DisplayPort monitors found." and the shell went off looking for a
# command called `No`. Hence the guard, and eval on purpose rather than by
# accident.
#
# The path was wrong too: it read ~/bin/screen/auto-ext.py, which run.sh has
# never created. Resolved next to this script instead, so it works wherever the
# repo is checked out and wherever ~/bin points.
set -u

here="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
cmd="$(python3 "$here/auto-ext.py")" || exit 1

case "$cmd" in
    xrandr\ *) ;;
    *)
        notify-send "Screen layout" "$cmd" 2>/dev/null
        echo "$cmd" >&2
        exit 1
        ;;
esac

eval "$cmd"
