#!/bin/bash

export TZ=America/Los_Angeles
pdt=`date +%H:%M`

export TZ=America/New_York
est=`date +%H:%M`

export TZ=Asia/Tehran
ir=`date +%H:%M`

export TZ=Asia/Muscat
om=`date +%H:%M`

export TZ=Europe/Dublin
ie=`date +%H:%M`

echo "%{F#F0C674}PDT%{F-} $pdt  |  %{F#F0C674}EST%{F-} $est  |  %{F#F0C674}IE%{F-} $ie  |  %{F#F0C674}IR%{F-} $ir  |  %{F#F0C674}OM%{F-} $om"
 
