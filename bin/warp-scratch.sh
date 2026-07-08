#!/usr/bin/env bash
# Toggle a dedicated dropdown Warp window in the i3 scratchpad ($mod+x).
# Warp windows can't be tagged with an X instance name (like `urxvt -name`),
# so we mark the window we spawn and reuse it.
mark="warpscratch"

# If our scratchpad Warp already exists, just toggle it into view.
if i3-msg "[con_mark=\"$mark\"] scratchpad show, resize set 90 ppt 85 ppt, move position center" \
   | grep -q '"success":true'; then
  exit 0
fi

# Otherwise spawn a new Warp, wait for its window, mark it, stash it, show it.
if ! command -v xdotool >/dev/null; then
  echo "xdotool required (sudo apt install xdotool)"; exit 1
fi
before=$(xdotool search --class "dev.warp.Warp" 2>/dev/null | sort)
warp-terminal >/dev/null 2>&1 &
for _ in $(seq 1 50); do
  sleep 0.1
  now=$(xdotool search --class "dev.warp.Warp" 2>/dev/null | sort)
  new=$(comm -13 <(echo "$before") <(echo "$now") | head -1)
  [ -n "$new" ] && break
done
[ -z "$new" ] && exit 0
i3-msg "[id=$new] mark $mark, move scratchpad"
i3-msg "[con_mark=\"$mark\"] scratchpad show, resize set 90 ppt 85 ppt, move position center"
