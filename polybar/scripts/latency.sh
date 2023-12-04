#!/bin/bash

# Define the target host you want to ping
target_host="google.com"

# Number of packets to send (you can adjust this)
num_packets=2

# Run the ping command and capture the output
ping_output=$(ping -c $num_packets $target_host)

# Extract the average latency (round-trip time) from the ping output
average_latency=$(echo "$ping_output" | grep -oP "rtt min/avg/max/mdev = \K[\d\.]+")

# Print the average latency
echo "$average_latency ms"

