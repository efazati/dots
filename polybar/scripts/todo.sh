#!/bin/bash 
dub=`date +%H:%M`

#todoist_cli sync
#line=$(todoist_cli list --filter '(overdue | today) & p1'  |  head -n 1 | cut -d " " -f 5-)
line=$(head -n 1 ~/todo)
echo "${dub} ~ ✪ ${line}"
 

