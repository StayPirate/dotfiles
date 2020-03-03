#!/bin/bash

# MAC addresses of authorized bluetooth devices 
# 04:52:C7:7E:67:82 - Crazybyte QC35
# 04:52:C7:7E:67:83 - placeholder
declare -a DEVS=("04:52:C7:7E:67:83" "04:52:C7:7E:67:82")

for DEV in "${DEVS[@]}"; do
    CONNECTED=$(bluetoothctl info "${DEV}" | grep -i connected | awk '{print $2}')
    if [[ "$CONNECTED" == "yes" ]]; then
        echo "${DEV}: Authorized device connected"
        if ps aux | grep [a]record; then
            killall arecord
        else
            dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
            arecord -f cd - | aplay -
        fi
        break
    fi
done
