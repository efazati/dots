#!/usr/bin/env bash
# Apply a screen layout and map the tablet onto one region of it.
#
#   wacom-setup.sh <layout-name> <WIDTHxHEIGHT+X+Y>
#   wacom-setup.sh 2mon-wacom 1920x1080+0+0
#
# The two callers (wacom.sh, wacom-4mon.sh) were identical apart from those two
# values, including the pad button map, which is the fiddly part and the part
# you least want to fix twice.
set -uo pipefail

layout_name="${1:?usage: wacom-setup.sh <layout-name> <WIDTHxHEIGHT+X+Y>}"
area="${2:?usage: wacom-setup.sh <layout-name> <WIDTHxHEIGHT+X+Y>}"

command -v xsetwacom >/dev/null || { echo "xsetwacom is not installed" >&2; exit 1; }

layout="$HOME/.screenlayout/${layout_name}.sh"
if [ ! -r "$layout" ]; then
    # Worth stopping for. Mapping a tablet onto a region of a layout that was
    # never applied puts the pen somewhere that is not on any screen, and the
    # symptom is a cursor that jumps off the edge rather than an error.
    echo "no screen layout at $layout (save one with arandr)" >&2
    exit 1
fi
bash "$layout"

# Read once and reuse. Two `xsetwacom --list` calls could disagree if a device
# is plugged or unplugged between them.
devices=$(xsetwacom --list devices)
if [ -z "$devices" ]; then
    echo "no wacom devices found" >&2
    exit 1
fi

ids=$(printf '%s\n' "$devices" | awk -F 'id: ' 'NF > 1 { print $2 }' | awk '{ print $1 }')
for id in $ids; do
    xsetwacom set "$id" MapToOutput "$area"
done

# The pad is the button block on the tablet itself, and its map is the reason
# these scripts exist rather than a one-line xsetwacom call.
pad_id=$(printf '%s\n' "$devices" | awk -F 'id: ' '/Pad pad/ && NF > 1 { print $2 }' | awk '{ print $1 }')
if [ -n "$pad_id" ]; then
    xsetwacom set "$pad_id" button 1 button 3
    xsetwacom set "$pad_id" Button 9 "key H"
    xsetwacom set "$pad_id" Button 8 "key p"
    xsetwacom set "$pad_id" Button 3 "key e"
    xsetwacom set "$pad_id" Button 2 "key ctrl z"
fi

echo "mapped $(printf '%s\n' "$ids" | grep -c .) wacom device(s) to $area"
