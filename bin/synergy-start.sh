#!/usr/bin/env bash
# Launch the Synergy 3 GUI only after its background service is ready.
# At login i3 would otherwise start the GUI before `synergy-service` is
# listening on 127.0.0.1:24803, causing ECONNREFUSED / "doesn't connect"
# (which a manual close+reopen "fixed"). Wait for the port, then launch.
for _ in $(seq 1 60); do
  ss -tln 2>/dev/null | grep -q "127.0.0.1:24803" && break
  sleep 0.5
done
# HOME/XDG paths must be the user's, not a leftover greeter (gdm) context.
export XDG_STATE_HOME="$HOME/.local/state"
exec /opt/Synergy/synergy --ozone-platform=x11
