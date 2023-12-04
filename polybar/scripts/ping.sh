#!/bin/bash 
ping=$(ping -c 1 1.1.1.1 | sed -n 2p | cut -d "=" -f 4); 
echo -e $ping


