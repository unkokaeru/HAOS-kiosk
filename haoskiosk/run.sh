#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# Clean up on exit:
TTY0_DELETED="" #Need to set to empty string since runs with nounset=on (like set -u)
trap '[ -n "$(jobs -p)" ] && kill $(jobs -p); [ -n "$TTY0_DELETED" ] && mknod -m 620 /dev/tty0 c 4 0 && mount -o remount,ro /dev; exit' INT TERM EXIT
################################################################################
# Add-on: HAOS Kiosk Display (haoskiosk)
# File: run.sh
# Version: 1.4.0
# Originally by Jeff Kosowsky, maintained by William Fayers
# Date: April 2026
#
#  Code does the following:
#     - Import and sanity-check the following variables from HA/config.yaml
#         HA_USERNAME
#         HA_PASSWORD
#         HA_URL
#         HA_DASHBOARD
#         LOGIN_DELAY
#         ZOOM_LEVEL
#         BROWSER_REFRESH
#         SCREEN_TIMEOUT
#         SCREEN_BRIGHTNESS
#         HDMI_PORT
#     - Hack to delete (and later restore) /dev/tty0 (needed for X to start)
#     - Start X window system
#     - Start Openbox window manager
#     - Start Dbus session
#     - Launch fresh Luakit browser for url: $HA_URL/$HA_DASHBOARD
#
################################################################################
bashio::log.info "Starting haoskiosk..."
### Get config variables from HA add-on & set environment variables
HA_USERNAME=$(bashio::config 'ha_username')
HA_USERNAME="${HA_USERNAME//null/}"

HA_PASSWORD=$(bashio::config 'ha_password')
HA_PASSWORD="${HA_PASSWORD//null/}"

HA_URL=$(bashio::config 'ha_url')
HA_URL="${HA_URL//null/}"
HA_URL="${HA_URL:-http://localhost:8123}"
HA_URL="${HA_URL%%/}" #Strip trailing slash

HA_DASHBOARD=$(bashio::config 'ha_dashboard')
HA_DASHBOARD="${HA_DASHBOARD//null/}"

LOGIN_DELAY=$(bashio::config 'login_delay')
LOGIN_DELAY="${LOGIN_DELAY//null/}"
LOGIN_DELAY="${LOGIN_DELAY:-3}"

ZOOM_LEVEL=$(bashio::config 'zoom_level')
ZOOM_LEVEL="${ZOOM_LEVEL//null/}"
ZOOM_LEVEL="${ZOOM_LEVEL:-100}"

BROWSER_REFRESH=$(bashio::config 'browser_refresh')
BROWSER_REFRESH="${BROWSER_REFRESH//null/}"
BROWSER_REFRESH="${BROWSER_REFRESH:-600}" #Default to 600 seconds

export HA_USERNAME HA_PASSWORD HA_URL HA_DASHBOARD LOGIN_DELAY ZOOM_LEVEL BROWSER_REFRESH #Referenced in 'userconf.lua'

SCREEN_TIMEOUT=$(bashio::config 'screen_timeout')
SCREEN_TIMEOUT="${SCREEN_TIMEOUT//null/}"
SCREEN_TIMEOUT="${SCREEN_TIMEOUT:-600}" #Default to 600 seconds

SCREEN_BRIGHTNESS=$(bashio::config 'screen_brightness')
SCREEN_BRIGHTNESS="${SCREEN_BRIGHTNESS//null/}"
SCREEN_BRIGHTNESS="${SCREEN_BRIGHTNESS:-100}" #Default to 100%

HDMI_PORT=$(bashio::config 'hdmi_port')
HDMI_PORT="${HDMI_PORT//null/}"
HDMI_PORT="${HDMI_PORT:-0}"
#NOTE: For now, both HDMI ports are mirrored and there is only /dev/fb0
#      Not sure how to get them unmirrored so that console can be on /dev/fb0 and X on /dev/fb1
#      As a result, setting HDMI=0 vs. 1 has no effect

#Validate environment variables set by config.yaml
if [ -z "$HA_USERNAME" ] || [ -z "$HA_PASSWORD" ]; then
    bashio::log.error "Error: HA_USERNAME and HA_PASSWORD must be set"
    exit 1
fi

################################################################################
### Start D-Bus session in the background (otherwise luakit hangs for 5 minutes before starting)
dbus-daemon --session --address="$DBUS_SESSION_BUS_ADDRESS" &

### Dynamically detect and configure input devices for Xorg
bashio::log.info "Detecting input devices..."
XORG_INPUT_DIR="/etc/X11/xorg.conf.d"
mkdir -p "$XORG_INPUT_DIR"
XORG_INPUT_CONF="${XORG_INPUT_DIR}/10-input-devices.conf"
: > "$XORG_INPUT_CONF"

# First pass: identify device capabilities to assign correct roles
POINTER_DEVICE=""
KEYBOARD_DEVICE=""
ALL_DEVICES=""
for event_device in /dev/input/event*; do
    [ -e "$event_device" ] || continue
    ALL_DEVICES="${ALL_DEVICES} ${event_device}"
    event_name=$(basename "$event_device")
    abs_caps=$(cat "/sys/class/input/${event_name}/device/capabilities/abs" 2>/dev/null) || true
    if echo "$abs_caps" | grep -q '[1-9a-f]'; then
        [ -z "$POINTER_DEVICE" ] && POINTER_DEVICE="$event_device"
        bashio::log.info "  ${event_device}: absolute axes detected (touchscreen/touchpad)"
    else
        [ -z "$KEYBOARD_DEVICE" ] && KEYBOARD_DEVICE="$event_device"
    fi
done

# Fallback: if no pointer found use second device; if no keyboard found use first
FIRST_DEVICE=$(echo "$ALL_DEVICES" | awk '{print $1}')
SECOND_DEVICE=$(echo "$ALL_DEVICES" | awk '{print $2}')
: "${KEYBOARD_DEVICE:=${FIRST_DEVICE}}"
: "${POINTER_DEVICE:=${SECOND_DEVICE:-${FIRST_DEVICE}}}"

# Second pass: generate InputDevice sections with capability-based roles
DEVICE_COUNT=0
LAYOUT_LINES=""
for event_device in /dev/input/event*; do
    [ -e "$event_device" ] || continue
    DEVICE_COUNT=$((DEVICE_COUNT + 1))
    device_id="Input${DEVICE_COUNT}"

    if [ "$event_device" = "$POINTER_DEVICE" ]; then
        role='"CorePointer"'
    elif [ "$event_device" = "$KEYBOARD_DEVICE" ]; then
        role='"CoreKeyboard"'
    else
        role='"SendCoreEvents"'
    fi

    cat >> "$XORG_INPUT_CONF" << INPUTEOF
Section "InputDevice"
    Identifier    "${device_id}"
    Driver        "evdev"
    Option        "Device" "${event_device}"
EndSection

INPUTEOF

    LAYOUT_LINES="${LAYOUT_LINES}    InputDevice    \"${device_id}\" ${role}
"
done

if [ "$DEVICE_COUNT" -eq 0 ]; then
    bashio::log.warning "No input devices found — adding AllowEmptyInput..."
    cat >> "$XORG_INPUT_CONF" << EMPTYEOF
Section "ServerFlags"
    Option "AllowEmptyInput" "on"
EndSection

EMPTYEOF
fi

for layout_index in 0 1; do
    cat >> "$XORG_INPUT_CONF" << LAYOUTEOF
Section "ServerLayout"
    Identifier     "Layout${layout_index}"
    Screen         "Screen${layout_index}" 0 0
${LAYOUT_LINES}EndSection

LAYOUTEOF
done

bashio::log.info "Configured ${DEVICE_COUNT} input device(s)..."

### Auto-detect DRI/KMS for modesetting driver (with fbdev fallback)
DRI_DEVICE=""
for dri_card in /dev/dri/card*; do
    [ -e "$dri_card" ] && DRI_DEVICE="$dri_card" && break
done

USE_MODESETTING=""
if [ -n "$DRI_DEVICE" ]; then
    bashio::log.info "Found DRI device ${DRI_DEVICE} — will attempt modesetting driver..."
    USE_MODESETTING=1
    # Back up original xorg.conf so we can revert on failure
    cp /etc/X11/xorg.conf /etc/X11/xorg.conf.fbdev
    sed -i 's/Driver.*"fbdev"/Driver        "modesetting"/' /etc/X11/xorg.conf
    sed -i '/Option.*"fbdev"/d' /etc/X11/xorg.conf
else
    bashio::log.info "No DRI device found — using fbdev driver (resolution set by firmware)..."
fi

#Note first need to delete /dev/tty0 since X won't start if it is there,
#because X doesn't have permissions to access it in the container
#First, remount /dev as read-write since X absolutely, must have /dev/tty access
#Note: need to use the version in util-linux, not busybox
if [ -e "/dev/tty0" ]; then
    bashio::log.info "Attempting to (temporarily) delete /dev/tty0..."
    if ! mount -o remount,rw /dev ; then
        bashio::log.error "Failed to remount /dev as read-write..."
        exit 1
    fi
    if ! rm /dev/tty0 ; then
        mount -o remount,ro /dev
        bashio::log.error "Failed to delete /dev/tty0..."
        exit 1
    fi
    TTY0_DELETED=1
    bashio::log.info "Deleted /dev/tty0 successfully..."
fi

### Start X server (with modesetting→fbdev fallback)
start_xorg() {
    rm -rf /tmp/.X*-lock /tmp/.X11-unix 2>/dev/null || true
    Xorg "$DISPLAY" -allowMouseOpenFail -layout "Layout${HDMI_PORT}" </dev/null &
    XORG_PID=$!
    local timeout=15
    for ((i=0; i<=timeout; i++)); do
        # Check if Xorg process died
        if ! kill -0 "$XORG_PID" 2>/dev/null; then
            return 1
        fi
        if xset q >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    # Timed out — kill and report failure
    kill "$XORG_PID" 2>/dev/null || true
    wait "$XORG_PID" 2>/dev/null || true
    return 1
}

if ! start_xorg; then
    if [ -n "$USE_MODESETTING" ]; then
        bashio::log.warning "Modesetting driver failed — falling back to fbdev..."
        cp /etc/X11/xorg.conf.fbdev /etc/X11/xorg.conf
        USE_MODESETTING=""
        if ! start_xorg; then
            bashio::log.error "Error: X server failed to start with both modesetting and fbdev drivers."
            exit 1
        fi
    else
        bashio::log.error "Error: X server failed to start."
        exit 1
    fi
fi

#Restore /dev/tty0 and 'ro' mode for /dev if deleted
if [ -n "$TTY0_DELETED" ]; then
    if ( mknod -m 620 /dev/tty0 c 4 0 && mount -o remount,ro /dev ); then
        bashio::log.info "Restored /dev/tty0 successfully..."
    else
        bashio::log.error "Failed to restore /dev/tty0 and remount /dev/ read only..."
    fi
fi

if ! xset q >/dev/null 2>&1; then
    bashio::log.error "Error: X server failed to start."
    exit 1
fi
bashio::log.info "X started successfully..."

#Stop console blinking cursor (this projects through the X-screen)
echo -e "\033[?25l" > /dev/console

### Start Openbox in the background
openbox &
O_PID=$!
sleep 0.5  #Ensure Openbox starts
if ! kill -0 "$O_PID" 2>/dev/null; then #Checks if process alive
    bashio::log.error "Failed to start Openbox window manager"
    exit 1
fi
bashio::log.info "Openbox started successfully..."

### Configure screen timeout (Note: DPMS needs to be enabled/disabled *after* starting Openbox)
if [ "$SCREEN_TIMEOUT" -eq 0 ]; then #Disable screen saver and DPMS for no timeout
    xset s 0
    xset dpms 0 0 0
    xset -dpms
    bashio::log.info "Screen timeout disabled..."
else
    xset s "$SCREEN_TIMEOUT"
    xset dpms "$SCREEN_TIMEOUT" "$SCREEN_TIMEOUT" "$SCREEN_TIMEOUT"  #DPMS standby, suspend, off
    xset +dpms
    bashio::log.info "Screen timeout after $SCREEN_TIMEOUT seconds..."
fi

### Configure display resolution and brightness via xrandr
# Note: fbdev driver has limited xrandr support; resolution is primarily
# controlled by the RPi firmware (config.txt). These calls are best-effort.
XRANDR_OUTPUT=$(xrandr --query 2>/dev/null | grep ' connected' | head -1 | awk '{print $1}') || true
if [ -n "$XRANDR_OUTPUT" ]; then
    PREFERRED_MODE=$(xrandr --query 2>/dev/null | grep -A1 "^${XRANDR_OUTPUT}" | tail -1 | awk '{print $1}') || true
    if [ -n "$PREFERRED_MODE" ]; then
        if xrandr --output "$XRANDR_OUTPUT" --mode "$PREFERRED_MODE" 2>/dev/null; then
            bashio::log.info "Display resolution set to ${PREFERRED_MODE} on ${XRANDR_OUTPUT}..."
        else
            bashio::log.info "Display using native resolution (mode switching not supported by driver)..."
        fi
    fi
    BRIGHTNESS_VALUE=$(awk "BEGIN {printf \"%.2f\", ${SCREEN_BRIGHTNESS} / 100}") || true
    if [ -n "$BRIGHTNESS_VALUE" ] && xrandr --output "$XRANDR_OUTPUT" --brightness "$BRIGHTNESS_VALUE" 2>/dev/null; then
        bashio::log.info "Screen brightness set to ${SCREEN_BRIGHTNESS}%..."
    else
        bashio::log.info "Software brightness not supported by driver — skipping..."
    fi
else
    bashio::log.warning "No display output detected by xrandr — skipping resolution and brightness..."
fi

### Run Luakit in the foreground
bashio::log.info "Launching Luakit browser..."
exec luakit -U "$HA_URL/$HA_DASHBOARD"
