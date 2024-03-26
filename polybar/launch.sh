#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Function to filter out unwanted network interfaces and check for assigned IP
get_network_interfaces() {
    local count=0
    # List all network interfaces
    for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
        # Skip unwanted interfaces
        if [[ "$iface" == "lo" || "$iface" == "virbr0" || "$iface" == "docker0" || "$iface" == br-* ]]; then
            continue
        fi

        # Check if the interface has an IP address
        if ip -o addr show $iface | grep -q "inet "; then
            echo "$iface"
            let count++
        fi

        # Break the loop if two interfaces are found
        if [[ $count -eq 2 ]]; then
            break
        fi
    done
}

# Get the first two active network interfaces
readarray -t networks < <(get_network_interfaces)
net1=${networks[0]}
net2=${networks[1]}

echo "Network 1: $net1"
echo "Network 2: $net2"


if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    line=$(xrandr --query | grep "${m}")
    if echo $line | grep -q "primary"; then
      echo "Primary found in line: $line"
      MONITOR=$m NETWORK_1=$net1 NETWORK_2=$net2 polybar --config=~/.config/polybar/config.ini --reload top-primary --quiet &
    else
      MONITOR=$m NETWORK_1=$net1 NETWORK_2=$net2 polybar --config=~/.config/polybar/config.ini --reload top --quiet &
    fi

    MONITOR=$m NETWORK_1=$net1 NETWORK_2=$net2 polybar --config=~/.config/polybar/config.ini --reload bot --quiet &
  done
else
  polybar --config=~/.config/polybar/config.ini --reload top bot --quiet &
  polybar --config=~/.config/polybar/config.ini --reload top top --quiet &
fi
