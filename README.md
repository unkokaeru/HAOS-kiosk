# HAOS Kiosk

A Home Assistant OS add-on that launches X-Windows on a local HAOS server followed by the Openbox window manager and Luakit browser, displaying Home Assistant dashboards in kiosk mode directly on the server's attached display. Standard mouse, keyboard, and touchscreen interactions work automatically.

## Attribution

This add-on is a fork of [HAOS-kiosk](https://github.com/puterboy/HAOS-kiosk) by **Jeff Kosowsky**. His original work provides the foundation for this project. A related fork by [argael](https://github.com/argael/HAOS-kiosk) also exists.

This fork is maintained by **William Fayers** ([@unkokaeru](https://github.com/unkokaeru)) at [unkokaeru/HAOS-kiosk](https://github.com/unkokaeru/HAOS-kiosk).

## Differences from Original

- **Smart touchscreen detection** — Reads kernel device capabilities (`/sys/class/input/`) to identify touchscreens via absolute axes, assigning them as `CorePointer` automatically.
- **Fixed auto-login** — Rewrote the JavaScript injection to correctly handle Home Assistant's Shadow DOM using the native `HTMLInputElement` setter, with retry/polling logic (up to 3 attempts).
- **DRI/modesetting auto-detection** — Automatically switches from `fbdev` to `modesetting` driver when DRI/KMS devices are available, with graceful fallback to `fbdev` if `modesetting` fails.
- **Web process crash recovery** — Automatically reloads the page after 2 seconds if the WebKit web process crashes.
- **Configurable screen brightness** — Software brightness control via xrandr (0–100%).
- **Expanded device support** — Supports up to 10 input devices (`event0`–`event9`) and DRI/GPU devices for proper resolution.
- **Increased default login delay** — Changed from `1.0s` to `3.0s` for more reliable auto-login on slower hardware.

## Installation

1. In Home Assistant, navigate to **Settings → Add-ons → Add-on Store**.
2. Click the **⋮** menu (top-right) and select **Repositories**.
3. Paste the following URL and click **Add**:

   ```
   https://github.com/unkokaeru/HAOS-kiosk
   ```

4. The **HAOS Kiosk** add-on will appear in the store. Click it and select **Install**.

## Configuration

All options are found in the add-on's **Configuration** tab.

| Option | Default | Description |
|---|---|---|
| **HA Username** *(required)* | — | Your Home Assistant login name. |
| **HA Password** *(required)* | — | Your Home Assistant password. |
| **HA URL** | `http://localhost:8123` | URL of your HA instance. Usually no need to change this since the add-on runs on the local server. |
| **HA Dashboard** | `""` (default Lovelace) | Name of the starting dashboard. Leave empty for the default Lovelace dashboard. |
| **Login Delay** | `3.0` seconds | Delay to allow the login page to load before auto-login attempts begin. |
| **HDMI Port** | `0` | HDMI output port (`0` or `1`). On stock HAOS on RPi, HDMI0 is mirrored to HDMI1. |
| **Screen Timeout** | `600` seconds | Time before the screen blanks. Set to `0` to disable. |
| **Screen Brightness** | `100`% | Software brightness via xrandr. `100` is full brightness, `0` is black. Not all drivers support this. |
| **Browser Refresh** | `600` seconds | Interval between browser refreshes. Set to `0` to disable. Recommended to keep enabled as console errors may overwrite the dashboard on RPi. |
| **Zoom Level** | `100`% | Browser zoom level. |

## Troubleshooting

### Resolution stuck at 1024×768

The `fbdev` driver uses the framebuffer resolution set by the Raspberry Pi firmware. To change it, SSH into HAOS and edit `/mnt/boot/config.txt`:

```
hdmi_group=2
hdmi_mode=82
```

Then reboot. This sets the output to 1920×1080 at 60 Hz.

### Touchscreen not responding

USB touchscreens (e.g., EVICIV portable monitors) send touch data via USB HID. Ensure you are using a **data-capable USB cable** — charge-only cables will not work. The touchscreen should appear as `/dev/input/event*` and will be detected automatically at startup (look for "absolute axes detected" in the add-on logs).

### Display does not appear

Reboot the Raspberry Pi with the display attached via HDMI. The framebuffer must be initialised at boot time.

## Usage Notes

- You **must** enter your HA username and password in the **Configuration** tab before the add-on will start.
- Luakit runs in **passthrough** mode (kiosk-like). In general, you want to stay in this mode.
  - **Exit passthrough:** press `Ctrl+Alt+Esc` to enter normal mode (similar to command mode in `vi`).
  - **Return to passthrough:** press `Ctrl+Z`, or press `i` to enter insert mode.
  - See the [Luakit documentation](https://luakit.github.io/) for all available commands.

## Licence

This project is licensed under the [GNU General Public License v2.0](LICENSE).
