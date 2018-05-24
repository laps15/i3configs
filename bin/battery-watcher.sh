#!/bin/bash

BAT_LOW_ICON='/usr/share/icons/Adwaita/scalable/status/battery-low-symbolic.svg'
BATTERIES='/sys/class/power_supply/BAT*/uevent'
TMP_FILE='/tmp/batfile.sh'
FULL_NOTIFIED=0

__beep() {
    (speaker-test -t sine -f 1000 &) >/dev/null;
    sleep 0.15s;
    pkill -9 speaker-test;
}

genSrcFile() {
    cat $BATTERIES | sed "s/\=/\=\'/g; s/$/'/g" > ${TMP_FILE}
}

getLevel() {
    source ${TMP_FILE};
    if [ "${POWER_SUPPLY_STATUS}" == "Charging" ]; then
        FULL_NOTIFIED=0
        echo '-1';
    elif [ "${POWER_SUPPLY_STATUS}" == "Full" ]; then
        echo -2;
    else
        echo "${POWER_SUPPLY_CAPACITY}";
    fi
}

main() {
    must_beep=1;
    thresh_hold=10;
    interval="5m"
    #getopts
    while [ 0 ]; do
        genSrcFile
        bat_lvl=$( getLevel );
        if [ ${bat_lvl} -gt 0 ]; then
            if [ ${bat_lvl} -lt ${thresh_hold} ]; then
                [ ${must_beep} -eq 1 ] &&\
                (__beep; __beep; __beep)&
                opts="-u critical -t 2000"
                summary="Battery level is bellow ${thresh_hold}%"
                text="Please charge"
                notify-send ${opts} "${summary}" "${text}"
            fi
        else
            if [ $FULL_NOTIFIED -eq 0 ]; then
                FULL_NOTIFIED=1
                if [ ${bat_lvl} -eq -2 ]; then
                    opts="-u critical -t 5000"
                    summary="Battery is already full"
                    notify-send ${opts} "${summary}" "${text}"
                fi
            fi
        fi
        sleep ${interval}
    done
}

tryLock() {
    flock -xn 200 
    return $?
}

tryUnlock() {
    flock --unlock 200
}

(
    summary="Battery watcher already running!"
    opts="-u critical -t 2000"
    tryLock || { notify-send ${opts} "${summary}"; exit 2; }
    trap tryUnlock INT EXIT

    main 200>&-

) 200>"${HOME}/.i3/.batwatch.lock"
