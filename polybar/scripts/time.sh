#!/bin/bash 


export TZ=America/Los_Angeles
pdt=`date +%H:%M`

export TZ=America/New_York
est=`date +%H:%M`

export TZ=Asia/Tehran
ir=`date +%H:%M`

echo "PDT $pdt  |  EST $est  |  IR $ir"
 
