################################################################################
# Add-on: HAOS Kiosk Display (haoskiosk)
# File: Dockerfile
# Version: 1.1.2
# Originally by Jeff Kosowsky, maintained by William Fayers
# Date: April 2026
################################################################################

ARG BUILD_FROM=ghcr.io/home-assistant/base:3.21
FROM $BUILD_FROM

# Install Luakit and necessary dependencies
RUN apk update && apk add --no-cache \
    luakit \
    xorg-server \
    xf86-video-fbdev \
    xf86-input-evdev \
    xf86-input-libinput \
    openbox \
    ttf-dejavu \
    util-linux \
    xset \
    xrandr \
    bash \
    mesa-gles \
    mesa-egl \
    && rm -rf /var/cache/apk/*

# Set the display and dbus environment variables
ENV DISPLAY=:0
ENV DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-session"

# Copy over 'xorg.conf' and lua 'userconf.lua' file
COPY xorg.conf /etc/X11/xorg.conf
COPY userconf.lua /root/.config/luakit/userconf.lua

COPY run.sh /
RUN chmod a+x /run.sh

CMD ["/run.sh"]
