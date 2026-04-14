#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# Clean up on exit:
TTY0_DELETED="" #Need to set to empty string since runs with nounset=on (like set -u)
trap '[ -n "$(jobs -p)" ] && kill $(jobs -p); [ -n "$TTY0_DELETED" ] && mknod -m 620 /dev/tty0 c 4 0 && mount -o remount,ro /dev; exit' INT TERM EXIT
################################################################################
# Add-on: HAOS Kiosk Display (haoskiosk)
# File: run.sh
# Version: 1.6.0
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
#         SCREEN_RESOLUTION
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

SCREEN_RESOLUTION=$(bashio::config 'screen_resolution')
SCREEN_RESOLUTION="${SCREEN_RESOLUTION//null/}"

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
    device_name=$(cat "/sys/class/input/${event_name}/device/name" 2>/dev/null) || true
    abs_caps=$(cat "/sys/class/input/${event_name}/device/capabilities/abs" 2>/dev/null) || true
    key_caps=$(cat "/sys/class/input/${event_name}/device/capabilities/key" 2>/dev/null) || true
    if echo "$abs_caps" | grep -q '[1-9a-f]'; then
        [ -z "$POINTER_DEVICE" ] && POINTER_DEVICE="$event_device"
        bashio::log.info "  ${event_device}: absolute axes detected — touchscreen/touchpad (${device_name})"
    elif echo "$key_caps" | grep -q '[1-9a-f]'; then
        [ -z "$KEYBOARD_DEVICE" ] && KEYBOARD_DEVICE="$event_device"
        bashio::log.info "  ${event_device}: keyboard (${device_name})"
    else
        bashio::log.info "  ${event_device}: other device (${device_name})"
    fi
done

if [ -z "$POINTER_DEVICE" ]; then
    bashio::log.warning "No touchscreen/touchpad detected — check USB cable and connection."
    bashio::log.warning "For USB touchscreen monitors, ensure a data-capable cable is connected to the touch port."
fi

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

# Log X input devices for diagnostics
XINPUT_LIST=$(xinput list 2>/dev/null) || true
if [ -n "$XINPUT_LIST" ]; then
    bashio::log.info "X input devices:"
    echo "$XINPUT_LIST" | while IFS= read -r line; do
        bashio::log.info "  $line"
    done
fi

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

### Configure display resolution via xrandr
XRANDR_OUTPUT=$(xrandr --query 2>/dev/null | grep ' connected' | head -1 | awk '{print $1}') || true
if [ -n "$XRANDR_OUTPUT" ]; then
    bashio::log.info "Display output detected: ${XRANDR_OUTPUT}"
    CURRENT_MODE=$(xrandr --query 2>/dev/null | grep '\*' | head -1 | awk '{print $1}') || true
    bashio::log.info "Current resolution: ${CURRENT_MODE:-unknown}"

    # If user specified a resolution, try to force it
    if [ -n "$SCREEN_RESOLUTION" ]; then
        bashio::log.info "User-requested resolution: ${SCREEN_RESOLUTION}"
        # Check if the mode already exists
        if xrandr --query 2>/dev/null | grep -q "${SCREEN_RESOLUTION}"; then
            if xrandr --output "$XRANDR_OUTPUT" --mode "$SCREEN_RESOLUTION" 2>/dev/null; then
                bashio::log.info "Display resolution set to ${SCREEN_RESOLUTION} on ${XRANDR_OUTPUT}..."
            else
                bashio::log.warning "Failed to set resolution ${SCREEN_RESOLUTION} — driver may not support mode switching."
            fi
        else
            # Mode doesn't exist — try to create it with cvt modeline
            bashio::log.info "Mode ${SCREEN_RESOLUTION} not available — attempting to create it..."
            XRES=$(echo "$SCREEN_RESOLUTION" | cut -dx -f1)
            YRES=$(echo "$SCREEN_RESOLUTION" | cut -dx -f2)
            MODELINE=$(cvt "$XRES" "$YRES" 60 2>/dev/null | grep "Modeline" | sed 's/Modeline //' | sed 's/"//g') || true
            if [ -n "$MODELINE" ]; then
                MODE_NAME=$(echo "$MODELINE" | awk '{print $1}')
                MODE_PARAMS=$(echo "$MODELINE" | cut -d' ' -f2-)
                # shellcheck disable=SC2086
                xrandr --newmode "$MODE_NAME" $MODE_PARAMS 2>/dev/null || true
                xrandr --addmode "$XRANDR_OUTPUT" "$MODE_NAME" 2>/dev/null || true
                if xrandr --output "$XRANDR_OUTPUT" --mode "$MODE_NAME" 2>/dev/null; then
                    bashio::log.info "Display resolution set to ${SCREEN_RESOLUTION} (custom mode) on ${XRANDR_OUTPUT}..."
                else
                    bashio::log.warning "Failed to set custom mode ${SCREEN_RESOLUTION} — fbdev driver does not support mode creation."
                    bashio::log.warning "To change resolution on RPi, set hdmi_group and hdmi_mode in /mnt/boot/config.txt."
                fi
            else
                bashio::log.warning "Could not generate modeline for ${SCREEN_RESOLUTION} — cvt not available or invalid resolution."
            fi
        fi
    else
        # No user override — try preferred mode
        PREFERRED_MODE=$(xrandr --query 2>/dev/null | grep -A1 "^${XRANDR_OUTPUT}" | tail -1 | awk '{print $1}') || true
        if [ -n "$PREFERRED_MODE" ] && [ "$PREFERRED_MODE" != "$CURRENT_MODE" ]; then
            if xrandr --output "$XRANDR_OUTPUT" --mode "$PREFERRED_MODE" 2>/dev/null; then
                bashio::log.info "Display resolution set to ${PREFERRED_MODE} on ${XRANDR_OUTPUT}..."
            else
                bashio::log.info "Display using native resolution (mode switching not supported by driver)..."
            fi
        else
            bashio::log.info "Display already at preferred resolution: ${CURRENT_MODE}"
        fi
    fi
else
    bashio::log.warning "No display output detected by xrandr — skipping resolution configuration..."
fi

### Configure screen brightness
if [ "$SCREEN_BRIGHTNESS" -ne 100 ]; then
    BRIGHTNESS_SET=""

    # Method 1: sysfs backlight (RPi DSI displays, embedded panels)
    BACKLIGHT_PATH=$(find /sys/class/backlight/ -maxdepth 1 -mindepth 1 2>/dev/null | head -1) || true
    if [ -n "$BACKLIGHT_PATH" ] && [ -z "$BRIGHTNESS_SET" ]; then
        MAX_BR=$(cat "${BACKLIGHT_PATH}/max_brightness" 2>/dev/null) || true
        if [ -n "$MAX_BR" ] && [ "$MAX_BR" -gt 0 ]; then
            TARGET_BR=$((SCREEN_BRIGHTNESS * MAX_BR / 100))
            if echo "$TARGET_BR" > "${BACKLIGHT_PATH}/brightness" 2>/dev/null; then
                bashio::log.info "Screen brightness set to ${SCREEN_BRIGHTNESS}% via backlight ($(basename "$BACKLIGHT_PATH"))..."
                BRIGHTNESS_SET=1
            fi
        fi
    fi

    # Method 2: DDC/CI via ddcutil (external HDMI monitors)
    if [ -z "$BRIGHTNESS_SET" ] && command -v ddcutil >/dev/null 2>&1; then
        modprobe i2c-dev 2>/dev/null || true
        if ddcutil setvcp 10 "$SCREEN_BRIGHTNESS" --noverify 2>/dev/null; then
            bashio::log.info "Screen brightness set to ${SCREEN_BRIGHTNESS}% via DDC/CI..."
            BRIGHTNESS_SET=1
        fi
    fi

    # Method 3: xrandr software brightness (modesetting driver only)
    if [ -z "$BRIGHTNESS_SET" ] && [ -n "$USE_MODESETTING" ] && [ -n "$XRANDR_OUTPUT" ]; then
        BRIGHTNESS_VALUE=$(awk "BEGIN {printf \"%.2f\", ${SCREEN_BRIGHTNESS} / 100}") || true
        if [ -n "$BRIGHTNESS_VALUE" ] && xrandr --output "$XRANDR_OUTPUT" --brightness "$BRIGHTNESS_VALUE" 2>/dev/null; then
            bashio::log.info "Screen brightness set to ${SCREEN_BRIGHTNESS}% via xrandr..."
            BRIGHTNESS_SET=1
        fi
    fi

    # No method worked
    if [ -z "$BRIGHTNESS_SET" ]; then
        bashio::log.warning "Could not set screen brightness — no supported method available."
        bashio::log.warning "Tried: sysfs backlight, DDC/CI (ddcutil), xrandr software brightness."
        bashio::log.warning "Ensure /dev/i2c-* is available for DDC/CI monitor control."
    fi
else
    bashio::log.info "Screen brightness at 100% (default)..."
fi

### Run Luakit in the foreground
bashio::log.info "Launching Luakit browser..."
exec luakit -U "$HA_URL/$HA_DASHBOARD"
