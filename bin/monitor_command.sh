#!/usr/bin/env bash
# Map every Wacom device onto one monitor, by monitor number.
#
#   monitor_command.sh        # the primary
#   monitor_command.sh 1      # the second monitor, as xrandr numbers them
#
# The numbers come from `xrandr --listactivemonitors`, so they match what you
# see there rather than what the tablet driver thinks.
set -uo pipefail

MON_NO="${1:-0}"

for cmd in xrandr xsetwacom; do
    command -v "$cmd" >/dev/null || { echo "$cmd is not installed" >&2; exit 1; }
done

# Anchored on the first field. The old pattern was a bare grep for "$MON_NO:",
# which also sees the geometry column, so asking for monitor 0 could match a
# line about a different one whose position happened to contain "0:".
MON_CON=$(xrandr --listactivemonitors | awk -v n="$MON_NO" '$1 == n":" { print $NF }')

if [ -z "$MON_CON" ]; then
    MON_COUNT=$(xrandr --listactivemonitors | awk '/^Monitors:/ { print $2 }')
    echo "no monitor with number $MON_NO was found" >&2
    echo "(a total of ${MON_COUNT:-0} monitors were found)" >&2
    # `exit -1` is not a thing: the shell keeps the low byte, so it became 255.
    exit 1
fi

# The mapping itself, which is the entire point of this script and the one thing
# it never did. The loop worked out each device id and then echoed it, so the
# script printed "Changed monitor for all wacom devices." having changed nothing.
mapped=0
while IFS= read -r line; do
    [ -n "$line" ] || continue
    id="${line##*id: }"
    id="${id%% *}"
    [ -n "$id" ] || continue
    if xsetwacom set "$id" MapToOutput "$MON_CON"; then
        mapped=$((mapped + 1))
    fi
done < <(xsetwacom list devices)

# Process substitution rather than a pipe into the loop, so `mapped` survives:
# a piped while runs in a subshell and its counter dies with it.

if [ "$mapped" -eq 0 ]; then
    echo "no wacom devices found, nothing mapped" >&2
    exit 1
fi

echo "mapped $mapped wacom device(s) to $MON_CON"
