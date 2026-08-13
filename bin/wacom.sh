#!/usr/bin/env bash
# Two-monitor setup: tablet on the left screen.
exec "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/wacom-setup.sh" 2mon-wacom 1920x1080+0+0
