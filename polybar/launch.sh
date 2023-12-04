#!/bin/bash

# Terminate already running bar instances
killall -q polybar

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    line=$(xrandr --query | grep "${m}")
    # Check if "primary" exists in the line
    if echo $line | grep -q "primary"; then
      # If "primary" exists in the line, do something. For instance, print a message.
      echo "Primary found in line: $line"
      
        MONITOR=$m polybar --reload top-primary &
    else
        MONITOR=$m polybar --reload top &
    fi

    MONITOR=$m polybar --reload bot &
  done
else
  polybar --reload top bot &
  polybar --reload top top &
fi