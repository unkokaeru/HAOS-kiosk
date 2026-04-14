# HAOS Kiosk

A Home Assistant OS add-on that launches X-Windows on a local HAOS server followed by the Openbox window manager and Luakit browser, displaying Home Assistant dashboards in kiosk mode directly on the server's attached display. Standard mouse, keyboard, and touchscreen interactions work automatically.

## Attribution

This add-on is a fork of [HAOS-kiosk](https://github.com/puterboy/HAOS-kiosk) by **Jeff Kosowsky**. His original work provides the foundation for this project. A related fork by [argael](https://github.com/argael/HAOS-kiosk) also exists.

This fork is maintained by **William Fayers** ([@unkokaeru](https://github.com/unkokaeru)) at [unkokaeru/HAOS-kiosk](https://github.com/unkokaeru/HAOS-kiosk).

## Differences from Original

- **Improved touchscreen support** — Added the `xf86-input-libinput` driver and automatic touchscreen detection via an `InputClass` section in `xorg.conf`.
- **Fixed auto-login** — Rewrote the JavaScript injection to correctly handle Home Assistant's Shadow DOM, and added retry/polling logic instead of relying on fixed timeouts.
- **Increased default login delay** — Changed from `1.0s` to `3.0s` for more reliable auto-login on slower hardware.
- **Expanded input device support** — Added more `/dev/input/event*` devices for broader hardware compatibility.

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
| **Browser Refresh** | `600` seconds | Interval between browser refreshes. Set to `0` to disable. Recommended to keep enabled as console errors may overwrite the dashboard on RPi. |
| **Zoom Level** | `100`% | Browser zoom level. |

## Usage Notes

- You **must** enter your HA username and password in the **Configuration** tab before the add-on will start.
- If the display does not appear, reboot with the display attached via HDMI.
- Luakit runs in **passthrough** mode (kiosk-like). In general, you want to stay in this mode.
  - **Exit passthrough:** press `Ctrl+Alt+Esc` to enter normal mode (similar to command mode in `vi`).
  - **Return to passthrough:** press `Ctrl+Z`, or press `i` to enter insert mode.
  - See the [Luakit documentation](https://luakit.github.io/) for all available commands.
- **Touchscreen support** works automatically — no additional configuration required.

## License

This project is licensed under the [GNU General Public License v2.0](LICENSE).
