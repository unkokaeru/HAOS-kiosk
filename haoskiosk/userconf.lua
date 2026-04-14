--[[
Add-on: HAOS Kiosk Display (haoskiosk)
File: userconf.lua for HA minimal browser run on server
Version: 1.2.1
Originally by Jeff Kosowsky, maintained by William Fayers
Date: April 2026

Code does the following:
    - Sets browser window to fullscreen
   - Sets zoom level to value of $ZOOM_LEVEL (default 100%)
    - Starts first window in 'passthrough' mode so that you can type text as needed without
      triggering browser commands
    - Auto-logs in to Home Assistant using $HA_USERNAME and $HA_PASSWORD
    - Redefines key to return to normal mode (used for commands) from 'passthrough' mode to: 'Ctl-Alt-Esc'
      (rather than just 'Esc') to prevent unintended returns to normal mode and activation of unwanted commands
    - Prevent printing of '--PASS THROUGH--' status line when in 'passthrough' mode
    - Set up periodic browser refresh every $BROWSER_REFRESH seconds (disabled if 0)
      NOTE: this is important since console messages overwrite dashboards
]]

-- -----------------------------------------------------------------------
-- Load required Luakit modules
local window = require "window"
local webview = require "webview"
local settings = require "settings"
local modes = package.loaded["modes"]

-- -----------------------------------------------------------------------
-- Load in environment variables to configure options
local username = os.getenv("HA_USERNAME") or ""
local password = os.getenv("HA_PASSWORD") or ""
local login_delay = tonumber(os.getenv("LOGIN_DELAY")) or 3 -- Delay in seconds before auto-login, default 3
local ha_url = os.getenv("HA_URL") or "http://localhost:8123"  -- Starting URL, default to local Home Assistant
ha_url = string.gsub(ha_url, "/+$", "") -- Strip trailing '/'
local browser_refresh = tonumber(os.getenv("BROWSER_REFRESH")) or 600  -- Refresh interval in seconds, default 600
local zoom_level = tonumber(os.getenv("ZOOM_LEVEL")) or 100

-- Escape a string for safe embedding inside a JavaScript double-quoted string
local function escape_for_javascript(value)
    value = string.gsub(value, "\\", "\\\\")
    value = string.gsub(value, '"', '\\"')
    value = string.gsub(value, "'", "\\'")
    value = string.gsub(value, "\n", "\\n")
    value = string.gsub(value, "\r", "\\r")
    return value
end

-- -----------------------------------------------------------------------
-- Set window to fullscreen
window.add_signal("init", function(w)
    w.win.fullscreen = true
end)

-- Set zoom level for windows (default 100%)
settings.webview.zoom_level = zoom_level

-- -----------------------------------------------------------------------
local first_window = true
webview.add_signal("init", function(view)
    -- Auto-reload on web process crash
    view:add_signal("crashed", function(v)
        local timer = require "lousy.util".timer
        local reload_timer = timer{interval = 2000}
        reload_timer:add_signal("timeout", function()
            reload_timer:stop()
            v:reload()
        end)
        reload_timer:start()
    end)

    -- Listen for page load events
    view:add_signal("load-status", function(v, status)
        if status ~= "finished" then return end  -- Only proceed when the page is fully loaded
        -- Start in passthrough mode so text input works without triggering browser commands
        if first_window then
            webview.window(v):set_mode("passthrough")
            first_window = false
        end

        -- Auto-login when the Home Assistant auth page is detected
        local auth_pattern = "^" .. ha_url .. "/auth/authorize%?response_type=code"
        if v.uri:match(auth_pattern) then
            local js_auto_login = string.format([[
                (function() {
                    function deepQuery(root, selector) {
                        var result = root.querySelector(selector);
                        if (result) return result;
                        var elements = root.querySelectorAll('*');
                        for (var index = 0; index < elements.length; index++) {
                            if (elements[index].shadowRoot) {
                                result = deepQuery(elements[index].shadowRoot, selector);
                                if (result) return result;
                            }
                        }
                        return null;
                    }

                    var nativeSetter = Object.getOwnPropertyDescriptor(
                        HTMLInputElement.prototype, 'value'
                    ).set;

                    function setFieldValue(field, value) {
                        nativeSetter.call(field, value);
                        field.dispatchEvent(new Event('input', {bubbles: true, composed: true}));
                        field.dispatchEvent(new Event('change', {bubbles: true, composed: true}));
                        field.dispatchEvent(new InputEvent('input', {
                            bubbles: true, composed: true, inputType: 'insertText', data: value
                        }));
                    }

                    function findField(nameSelector, typeSelector) {
                        return deepQuery(document, nameSelector)
                            || deepQuery(document, typeSelector);
                    }

                    function clickSubmit() {
                        var submit = deepQuery(document, 'mwc-button')
                            || deepQuery(document, 'ha-button')
                            || deepQuery(document, 'button[type="submit"]');
                        if (submit) {
                            submit.click();
                            return true;
                        }
                        return false;
                    }

                    function attemptLogin() {
                        var usernameField = findField(
                            'input[name="username"]', 'input[type="text"]'
                        );
                        var passwordField = findField(
                            'input[name="password"]', 'input[type="password"]'
                        );
                        if (!usernameField || !passwordField) return false;

                        setFieldValue(usernameField, "%s");
                        setFieldValue(passwordField, "%s");

                        setTimeout(function() {
                            if (!clickSubmit()) {
                                passwordField.dispatchEvent(new KeyboardEvent('keydown', {
                                    key: 'Enter', code: 'Enter', keyCode: 13,
                                    bubbles: true, composed: true
                                }));
                            }
                        }, 500);
                        return true;
                    }

                    var loginAttempts = 0;
                    var maxLoginAttempts = 3;
                    var pollAttempts = 0;
                    var maxPollAttempts = 50;
                    var pollInterval = %d;

                    var interval = setInterval(function() {
                        pollAttempts++;
                        if (attemptLogin()) {
                            clearInterval(interval);
                            loginAttempts++;
                            if (loginAttempts < maxLoginAttempts) {
                                setTimeout(function() {
                                    if (window.location.href.indexOf('/auth/authorize') !== -1) {
                                        pollAttempts = 0;
                                        interval = setInterval(function() {
                                            pollAttempts++;
                                            if (attemptLogin() || pollAttempts >= maxPollAttempts) {
                                                clearInterval(interval);
                                            }
                                        }, pollInterval);
                                    }
                                }, 3000);
                            }
                        }
                        if (pollAttempts >= maxPollAttempts) clearInterval(interval);
                    }, pollInterval);
                })();
            ]], escape_for_javascript(username), escape_for_javascript(password), login_delay * 1000 / 50)
            v:eval_js(js_auto_login, { source = "auto_login.js" })
        end

        -- Set up periodic page refresh if browser_refresh is positive
        if browser_refresh > 0 then
            local js_refresh = string.format([[
                if (window.refreshInterval) clearInterval(window.refreshInterval);
                window.refreshInterval = setInterval(function() {
                    location.reload();
                }, %d);
            ]], browser_refresh * 1000)
            v:eval_js(js_refresh, { source = "auto_refresh.js" })  -- Execute the refresh script
        end
    end)
end)

-- -----------------------------------------------------------------------
-- Redefine <Esc> to <Ctl-Alt-Esc> to exit current mode and enter normal mode
modes.remove_binds({"passthrough"}, {"<Escape>"})
modes.add_binds("passthrough", {
    {"<Control-Mod1-Escape>", "Switch to normal mode", function(w)
        w:set_prompt()
        w:set_mode()
     end}
})

-- Clear the command line when entering passthrough instead of typing '-- PASS THROUGH --'
modes.get_modes()["passthrough"].enter = function(w)
    w:set_prompt()            -- Clear the command line prompt
    w:set_input()             -- Activate the input field (e.g., URL bar or form)
    w.view.can_focus = true   -- Ensure the webview can receive focus
    w.view:focus()            -- Focus the webview for keyboard input
end

