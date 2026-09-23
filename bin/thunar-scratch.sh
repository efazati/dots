#!/usr/bin/env bash
# Toggle Thunar as a floating scratchpad window ($mod+Shift+v).
# i3's for_window rule marks the main Thunar window "files" and parks it in the
# scratchpad. Sizing and centering happen here, on every show, so the window
# always lands inside the focused monitor even if it was last shown on the
# other one or was created before i3 knew its final size.
mark="files"
show='scratchpad show, resize set 80 ppt 80 ppt, move position center'

# Check the mark list, not pgrep: `thunar --daemon` can run with no window.
if i3-msg -t get_marks | grep -q "\"$mark\""; then
  i3-msg "[con_mark=\"$mark\"] $show" >/dev/null
  exit 0
fi

thunar >/dev/null 2>&1 &
for _ in $(seq 1 50); do
  sleep 0.1
  i3-msg -t get_marks | grep -q "\"$mark\"" && break
done
i3-msg "[con_mark=\"$mark\"] $show" >/dev/null
# A fresh Thunar can move its own window a moment after mapping, which pushed
# it past the screen edge. run.sh turns off misc-remember-geometry for the
# main cause; centering again once it has settled catches the rest.
for delay in 0.4 0.6; do
  sleep "$delay"
  i3-msg "[con_mark=\"$mark\"] resize set 80 ppt 80 ppt, move position center" >/dev/null
done
