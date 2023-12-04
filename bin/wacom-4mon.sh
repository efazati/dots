#!/bin/bash

bash ~/.screenlayout/4mon-wacom.sh

# get the list of devices and their respective IDs
devices=$(xsetwacom --list devices | awk -F 'id: ' '{ print $2 }' | awk '{ print $1 }')

# loop through the list of devices and perform the necessary operations
for id in $devices
do
    xsetwacom set $id MapToOutput 1920x1080+1920+0
done

# get the id of the device that has "Pad pad" in its name
pad_id=$(xsetwacom --list devices | grep "Pad pad" | awk -F 'id: ' '{ print $2 }' | awk '{ print $1 }')

# run the necessary commands for the "Pad pad" device
if [[ ! -z "$pad_id" ]]; then
    xsetwacom set $pad_id button 1 button 3
    xsetwacom set $pad_id Button 9 "key H"
    xsetwacom set $pad_id Button 8 "key p"
    xsetwacom set $pad_id Button 3 "key e"
    xsetwacom set $pad_id Button 2 "key ctrl z"
fi
