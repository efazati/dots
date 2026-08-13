#!/usr/bin/env bash
# Four-monitor setup: tablet on the second screen across.
exec "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/wacom-setup.sh" 4mon-wacom 1920x1080+1920+0
