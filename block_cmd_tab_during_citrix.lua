-- ============================================================
-- CONFIGURATION: Citrix and other Remote Desktop apps
-- ============================================================
local ignoredApps = {
    ["Citrix Viewer"] = true,
    ["Citrix Workspace"] = true,
    ["Citrix Receiver"] = true,
    ["Microsoft Remote Desktop"] = true
}

local function isIgnoredAppActive()
    local app = hs.application.frontmostApplication()
    return app and (ignoredApps[app:name()] or ignoredApps[app:title()])
end

-- ============================================================
-- Main Event Handler (Y/Z swap, í/0 logic, and Cmd+Tab blocking)
-- ============================================================
local eventtap = hs.eventtap
local eventTypes = hs.eventtap.event.types

YZSwapper = {}
local tab_code = 48

YZSwapper.watcher = eventtap.new({eventTypes.keyDown, eventTypes.keyUp, eventTypes.keyRepeat, eventTypes.flagsChanged}, function(event)
    local keyCode = event:getKeyCode()
    local flags = event:getFlags()
    local type = event:getType()
    local char = event:getCharacters()
    
    -- BLOCK CMD+TAB FOR CITRIX
    -- If Cmd is held and Tab is pressed while in an ignored app, stop the event.
    if keyCode == tab_code and flags.cmd then
        if isIgnoredAppActive() then
            return true -- "Eat" the event so macOS doesn't see it
        end
    end
    
    return false
end)

-- ============================================================
-- Menubar Initialization and Control
-- ============================================================
YZSwapper.menubar = hs.menubar.new()
function YZSwapper.updateMenu()
    local status = YZSwapper.watcher:isEnabled() and "ACTIVE" or "FIX"
    YZSwapper.menubar:setTitle(status)
end

YZSwapper.menubar:setClickCallback(function()
    if YZSwapper.watcher:isEnabled() then 
        YZSwapper.watcher:stop() 
    else 
        YZSwapper.watcher:start() 
    end
    YZSwapper.updateMenu()
end)

-- Start the script
YZSwapper.watcher:start()
YZSwapper.updateMenu()
hs.alert.show("Keyboard script is loaded")
