#!/bin/bash

CON=$(ifconfig | grep wlp)

if [ "$CON" == "" ]; then
    ACT='on'
else
    ACT='off'
fi

nmcli r wifi ${ACT}

