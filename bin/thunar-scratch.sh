#!/usr/bin/env bash
# Toggle Thunar as a floating scratchpad window ($mod+Shift+v).
# i3's for_window rule sends every Thunar window to the scratchpad, so here we
# only decide between "show/hide what exists" and "launch it".
# Check the tree for a real window rather than pgrep: `thunar --daemon` can be
# running with no window, and then scratchpad show would match nothing.
if i3-msg -t get_tree | grep -q '"class":"Thunar"'; then
  i3-msg '[class="Thunar"] scratchpad show, resize set 80 ppt 80 ppt, move position center' >/dev/null
else
  thunar >/dev/null 2>&1 &
fi
