# Changelog

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
