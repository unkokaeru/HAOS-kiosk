# Changelog

## v1.6.0 – April 2026

- Replaced broken brightness control with a 3-method cascade: sysfs backlight (RPi DSI
  displays), DDC/CI via ddcutil (external HDMI monitors), and xrandr software brightness
  (modesetting driver) — each method is tried in order until one succeeds
- Removed xgamma gamma-correction fallback that destroyed contrast by incorrectly mapping
  brightness to gamma
- Added `ddcutil` package and `/dev/i2c-*` device passthrough for DDC/CI monitor control
- Updated documentation with brightness troubleshooting guidance

## v1.5.0 – April 2026

- Added `screen_resolution` configuration option with xrandr mode override and cvt modeline
  generation for forcing a specific resolution (e.g., `1920x1080`)
- Added xgamma fallback for software brightness when xrandr brightness is not supported
- Added `xinput list` diagnostic logging after X starts to help debug input issues
- Expanded device passthrough to event0–19 and hidraw0–4 for USB touchscreen monitors
- Enhanced input device diagnostics with sysfs device names and touchscreen detection warnings
- Added `xinput`, `xgamma` packages to Docker image
- Updated documentation with screen resolution option and troubleshooting guidance

## v1.4.0 – April 2026

- Fixed duplicate `mount` call that was unreachable under `set -e` error handling
- Fixed unquoted variable expansion in device detection (`$ALL_DEVICES`)
- Removed extra whitespace in `rm` condition
- Corrected file header date from 2025 to 2026 and added missing `SCREEN_BRIGHTNESS` variable
- Added clarifying comments to `xorg.conf` explaining inactive `libinput` InputClass sections
- Fixed indentation alignment in `userconf.lua` header
- Updated both READMEs with comprehensive feature list, troubleshooting section, and
  `Screen Brightness` configuration option
- Corrected "License" → "Licence" (Oxford UK spelling)

## v1.3.1 – April 2026

- Modesetting driver now falls back gracefully to fbdev if X fails to start
  (RPi DRI devices are present but may not support modesetting in containers)
- X startup wrapped in retry function with proper process cleanup
- Backs up xorg.conf before modifying, restores on fallback

## v1.3.0 – April 2026

- Smart input device detection — reads kernel capabilities (`/sys/class/input/`)
  to identify touchscreens (absolute axes) and assign them as `CorePointer` instead
  of blindly assigning the first device as `CoreKeyboard`
- Auto-detects DRI/KMS devices and switches from `fbdev` to `modesetting` driver for
  proper resolution support (e.g., 1080p on EVICIV portable monitors)
- Added `/dev/dri/card0`, `/dev/dri/card1`, `/dev/dri/renderD128` to device access list
- Expanded input device support to `event0`–`event9` for USB peripherals
- Logs which devices have absolute axes (touchscreen/touchpad) during startup

## v1.2.1 – April 2026

- Fixed startup crash caused by `xrandr --brightness` failing under the `fbdev` driver —
  all xrandr calls are now non-fatal with graceful fallback logging

## v1.2.0 – April 2026

- Fixed Screen sections referencing non-existent `FBDEV` device — now correctly
  point to `FBDEV0` and `FBDEV1`, resolving resolution detection issues
- Added `screen_brightness` configuration option (0–100) using xrandr software brightness
- Display resolution now automatically set to the highest available mode via xrandr
- Expanded input device support from 6 to 10 (`event0`–`event9`) for USB touchscreens
- Added `xrandr` package to the container

## v1.1.2 – April 2026

- Installed `mesa-gles` and `mesa-egl` to provide `libGLESv2.so.2` — prevents WebKit
  GPU process crash when rendering the Home Assistant dashboard
- Added automatic page reload on web process crash (2-second delay)

## v1.1.1 – April 2026

- Switched dynamic input devices from `libinput` to `evdev` driver — `libinput` requires
  `udev` device initialisation which is unavailable in Docker containers

## v1.1.0 – April 2026

- Dynamic input device detection at startup — all `/dev/input/event*` devices are now
  auto-configured with evdev, replacing fragile hardcoded mappings
- Touchscreen, touchpad, keyboard, and mouse are all handled automatically regardless
  of device numbering
- Added `-allowMouseOpenFail` flag to Xorg for resilience when devices are absent
- Added `AllowEmptyInput` fallback when no input devices are found
- Auto-login now retries up to 3 times if the auth page persists after submission
- Added fallback field selectors (`input[type="text"]`, `input[type="password"]`) for
  broader compatibility with Home Assistant UI variants
- Added `InputEvent` dispatch alongside `Event` for framework compatibility
- Removed hardcoded `InputDevice` and `ServerLayout` sections from `xorg.conf`

## v1.0.0 – April 2026

- Forked from [puterboy/HAOS-kiosk](https://github.com/puterboy/HAOS-kiosk) by Jeff Kosowsky
- Added proper touchscreen support via `xf86-input-libinput` driver with automatic detection
- Fixed auto-login to work with Home Assistant's Shadow DOM-based auth page
- Added retry/polling logic for more reliable auto-login
- Increased default login delay from 1.0s to 3.0s
- Expanded input device support for broader hardware compatibility
- Updated documentation and branding

## v0.9.7 – April 2025

- Initial public release
- Added Zoom capability

## v0.9.6 – March 2025

- Initial private release
