#!/bin/sh

CAPS=0
NUM=0
OUT=""

update_out() {
    res=$(xset q | grep mask | sed "s/.*mask://")
    CAPS=$((${res}&1))
    NUM=$((${res}&2))
    OUT=""
    if [ ${CAPS} -eq 1 ]; then
        OUT=${OUT}"CAPS";
    fi
    if [ ${NUM} -eq 2 ]; then
        if [ ${CAPS} -eq 1 ]; then
            OUT=${OUT}"|"
        fi
        OUT=${OUT}"NUM";
    fi
}

OUTMUS=""

update_song() {
    res=$(pgrep spotify)
    OUTMUS=""
    if [ "$res" != "" ]; then
        reply=$()
        song=$(dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata' | grep title -A1 | tail -1 | grep string | sed "s/.*string //" | tr -d '"')
        artist=$(dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata' | grep artist -A5 | tail -5 | grep string | sed "s/.*string //" | tr -d '"')
        OUTMUS="♪: '${song}' by '${artist}'"
    fi
}

i3status | (read line && echo "$line" && read line && echo "$line" && read line && echo "$line" && update_out && update_song && while :
do
    read line
    update_out
    update_song
    echo ",[{\"full_text\":\"${OUTMUS}\"},{\"full_text\":\"${OUT}\" },${line#,\[}" || exit 1
done)
