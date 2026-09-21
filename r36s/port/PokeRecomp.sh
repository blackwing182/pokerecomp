#!/bin/bash
# PokéRecomp — R36S / RK3326
# PortMaster + WestonPack launcher.
set -e

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
    controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
    controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
    controlfolder="$XDG_DATA_HOME/PortMaster"
else
    controlfolder="/roms/ports/PortMaster"
fi

source "$controlfolder/control.txt"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR=/$directory/ports/pokerecomp-r36s
GAME="$GAMEDIR/pokerecomp-r36s"

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

CONFDIR="$GAMEDIR/conf"
$ESUDO mkdir -p "$CONFDIR"

weston_dir=/tmp/weston
$ESUDO mkdir -p "$weston_dir"
weston_runtime="weston_pkg_0.2"

if [ ! -f "$controlfolder/libs/${weston_runtime}.squashfs" ]; then
    if [ ! -f "$controlfolder/harbourmaster" ]; then
        pm_message "PokéRecomp R36S requires the PortMaster WestonPack runtime."
        sleep 5
        exit 1
    fi
    $ESUDO "$controlfolder/harbourmaster" --quiet --no-check \
        runtime_check "${weston_runtime}.squashfs"
fi

if [[ "$PM_CAN_MOUNT" != "N" ]]; then
    $ESUDO umount "$weston_dir" 2>/dev/null || true
fi

$ESUDO mount "$controlfolder/libs/${weston_runtime}.squashfs" "$weston_dir"

cd "$GAMEDIR"

# WestonPack provides Xwayland/EGL on stock R36S/PortMaster systems, avoiding
# the unavailable native X11 display server.
$ESUDO env \
    CRUSTY_BLOCK_INPUT=1 \
    XDG_DATA_HOME="$CONFDIR" \
    "$weston_dir/westonwrap.sh" headless noop kiosk crusty_x11egl \
    WAYLAND_DISPLAY= \
    "$GAME" \
    --resolution 640x480 \
    -f \
    --rendering-driver opengl3_es \
    --audio-driver ALSA

status=$?

$ESUDO "$weston_dir/westonwrap.sh" cleanup || true

if [[ "$PM_CAN_MOUNT" != "N" ]]; then
    $ESUDO umount "$weston_dir" 2>/dev/null || true
fi

pm_finish
exit "$status"
