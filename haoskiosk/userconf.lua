--[[
Add-on: HAOS Kiosk Display (haoskiosk)
File: userconf.lua for HA minimal browser run on server
Version: 1.0.0
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
    -- Listen for page load events
    view:add_signal("load-status", function(v, status)
        if status ~= "finished" then return end  -- Only proceed when the page is fully loaded
        -- Start in passthrough mode so text input works without triggering browser commands
        if first_window then
            webview.window(v):set_mode("passthrough")
            first_window = false
        end

        -- Set up auto-login for Home Assistant
        -- Check if the current URL matches the Home Assistant auth page
        local auth_pattern = "^" .. ha_url .. "/auth/authorize%?response_type=code"
        if v.uri:match(auth_pattern) then
            -- JavaScript to auto-fill and submit the login form
            -- Uses Shadow DOM traversal since HA uses web components
            local js_auto_login = string.format([[
                (function() {
                    function deepQuery(root, selector) {
                        var result = root.querySelector(selector);
                        if (result) return result;
                        var elements = root.querySelectorAll('*');
                        for (var i = 0; i < elements.length; i++) {
                            if (elements[i].shadowRoot) {
                                result = deepQuery(elements[i].shadowRoot, selector);
                                if (result) return result;
                            }
                        }
                        return null;
                    }
                    var attempts = 0;
                    var maxAttempts = 50;
                    var interval = setInterval(function() {
                        attempts++;
                        var usernameField = deepQuery(document, 'input[name="username"]');
                        var passwordField = deepQuery(document, 'input[name="password"]');
                        if (usernameField && passwordField) {
                            clearInterval(interval);
                            usernameField.value = "%s";
                            passwordField.value = "%s";
                            usernameField.dispatchEvent(new Event('input', {bubbles: true}));
                            passwordField.dispatchEvent(new Event('input', {bubbles: true}));
                            setTimeout(function() {
                                var submit = deepQuery(document, 'mwc-button') || deepQuery(document, 'ha-button') || deepQuery(document, 'button[type="submit"]');
                                if (submit) submit.click();
                            }, 500);
                        }
                        if (attempts >= maxAttempts) clearInterval(interval);
                    }, %d);
                })();
            ]], escape_for_javascript(username), escape_for_javascript(password), login_delay * 1000 / 50)
            v:eval_js(js_auto_login, { source = "auto_login.js" })  -- Execute the login script
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

