#!/bin/sh
if type scrcpy >/dev/null ; then
    _height=$(xrandr | grep ' connected' | grep -Eo "[0-9]+x[0-9]+" | cut -d'x' -f2 | tail -n1)
    scrcpy --serial d64c428 --window-x 0 --window-y 1900 --max-size $_height --turn-screen-off --window-borderless
else
    echo "scrcpy not found"
fi
