#!/bin/bash

BAT_LOW_ICON='/usr/share/icons/Adwaita/scalable/status/battery-low-symbolic.svg'
BATTERIES='/sys/class/power_supply/BAT*/uevent'
TMP_FILE='/tmp/batfile.sh'

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
        echo '-1';
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
        if [ ! ${bat_lvl} -eq -1 ]; then
            if [ ${bat_lvl} -lt ${thresh_hold} ]; then
                [ ${must_beep} -eq 1 ] &&\
                (__beep; __beep; __beep)&
                opts="-u critical -t 7770"
                summary="Battery level is bellow ${thresh_hold}%"
                text="Please charge"
                notify-send ${opts} "${summary}" "${text}"
            fi
        fi
        sleep ${interval}
    done
}

tryLock() {
    flock -xn 777 
    return $?
}

tryUnlock() {
    flock -u 777
}

(
    summary="Battery watcher already running!"
    opts="-u critical -t 7770"
    tryLock || { notify-send ${opts} "${summary}"; exit 2; }
    trap tryUnlock EXIT

    main 777>&-

) 777>"${HOME}/.i3/.batwatch.lock"
