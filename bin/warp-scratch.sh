#!/usr/bin/env bash
# Toggle a dropdown Warp window in the i3 scratchpad ($mod+x).
# Warp is single-instance (no --new-window flag), so we adopt whatever Warp
# window exists as the dropdown: mark it once, then scratchpad-show toggles it.
mark="warpscratch"
show='scratchpad show, resize set 90 ppt 85 ppt, move position center'

# Already adopted? Toggle it in/out of view.
# (Check the mark list directly — a combined i3 command reports success:true
# from its resize/move parts even when [con_mark] matches no window.)
if i3-msg -t get_marks | grep -q "\"$mark\""; then
  i3-msg "[con_mark=\"$mark\"] $show" >/dev/null
  exit 0
fi

# Not adopted yet. Find an existing Warp window and adopt it.
win=$(xdotool search --class "dev.warp.Warp" 2>/dev/null | head -1)

# None open: launch Warp and wait for its window.
if [ -z "$win" ]; then
  command -v xdotool >/dev/null || { echo "xdotool required (sudo apt install xdotool)"; exit 1; }
  warp-terminal >/dev/null 2>&1 &
  for _ in $(seq 1 50); do
    sleep 0.1
    win=$(xdotool search --class "dev.warp.Warp" 2>/dev/null | head -1)
    [ -n "$win" ] && break
  done
fi
[ -z "$win" ] && exit 0

i3-msg "[id=$win] mark $mark, move scratchpad"
i3-msg "[con_mark=\"$mark\"] $show"
