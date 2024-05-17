#!/bin/bash

LOGFILE=$1

cat $1 | grep -v WARN | grep -v Reading | grep -v mutex | grep -v Preparing | grep -v Configured | grep -v "End of run" | grep -v Stopping | grep -v "Moving" | grep -v "Event limit" | sed -r 's/^.{5}//' | cut -f 1 -d "/" | sed 's/RunControl//g' | sed 's/DataCollector//g' | sed 's/Configuring/\nConfiguring/g' | grep -v "Out of sync" | grep -v "Connection" | grep -v "started" | grep -v "Disconnected" | grep -v "Terminating" | while read l
do
    #echo $l
    if [ "${#l}" -eq 0 ]
    then
        echo -e $RUN_NUMBER'\t'$RUN_START_DATE'\t'$RUN_START_TIME'\t'$RUN_END_TIME'\t'$EVENT_COUNT'\t'$CONFIG_FILE
        CONFIG_FILE="-"
        RUN_NUMBER="-"
        RUN_START_DATE="-"
        RUN_START_TIME="-"
        EVENT_COUNT="-"
        RUN_END_DATE="-"
        RUN_END_TIME="-"
    fi
    if [[ $l == Configuring* ]]
    then
        CONFIG_FILE=$(echo $l | cut -f2 -d"(" | cut -f1 -d")")".conf"
    fi
    if [[ $l == Starting\ Run* ]]
    then
        RUN_NUMBER=$(echo $l | cut -f3 -d' ' | sed 's/://')
        RUN_START_DATE=$(echo $l | cut -f4 -d' ')
        RUN_START_TIME=$(echo $l | cut -f5 -d' ' | cut -f1 -d'.')
    fi
    if [[ $l == *EORE* ]]
    then
        EVENT_COUNT=$(echo $l | cut -f5 -d' ')
        RUN_END_DATE=$(echo $l | cut -f6 -d' ')
        RUN_END_TIME=$(echo $l | cut -f7 -d' ' | cut -f1 -d'.')
    fi
done
