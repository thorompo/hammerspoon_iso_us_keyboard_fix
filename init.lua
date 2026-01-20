-- ============================================================
-- 1. CONFIGURATION: Citrix and other Remote Desktop apps
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
-- 2. PART: Cmd+Q Protection (Double Cmd+Q to quit)
-- ============================================================
local quitModal = hs.hotkey.modal.new('cmd','q')
function quitModal:entered()
    if isIgnoredAppActive() then
        quitModal:exit()
        hs.eventtap.keyStroke({'cmd'}, 'q', 0)
        return
    end
    hs.alert.show("Double Cmd+Q to quit", 1)
    hs.timer.doAfter(1, function() quitModal:exit() end)
end
quitModal:bind('cmd', 'q', function() 
    local app = hs.application.frontmostApplication()
    if app then app:kill() end
end)
quitModal:bind('', 'escape', function() quitModal:exit() end)

-- ============================================================
-- 3. PART: Main Event Handler (Y/Z swap, í/0 logic, and Cmd+Tab blocking)
-- ============================================================
local eventtap = hs.eventtap
local eventTypes = hs.eventtap.event.types

YZSwapper = {}
local y_code = 16
local z_code = 6
local tab_code = 48

YZSwapper.watcher = eventtap.new({eventTypes.keyDown, eventTypes.keyUp, eventTypes.keyRepeat, eventTypes.flagsChanged}, function(event)
    local keyCode = event:getKeyCode()
    local flags = event:getFlags()
    local type = event:getType()
    local char = event:getCharacters()
    
    -- A. BLOCK CMD+TAB FOR CITRIX
    -- If Cmd is held and Tab is pressed while in an ignored app, stop the event.
    if keyCode == tab_code and flags.cmd then
        if isIgnoredAppActive() then
            return true -- "Eat" the event so macOS doesn't see it
        end
    end

    -- B. SWAP Y AND Z KEYS
    if keyCode == y_code then
        event:setKeyCode(z_code)
        return false
    elseif keyCode == z_code then
        event:setKeyCode(y_code)
        return false
    end

    -- C. CHARACTER REPLACEMENT LOGIC (í/Í key)
    if type == eventTypes.keyDown or type == eventTypes.keyRepeat then
        if char == "í" or char == "Í" then
            if flags.fn then return false end
            if char == "Í" then return false end
            if char == "í" then
                hs.eventtap.keyStrokes("0")
                return true
            end
        end
    end
    
    return false
end)

-- ============================================================
-- 4. PART: Menubar Initialization and Control
-- ============================================================
YZSwapper.menubar = hs.menubar.new()
function YZSwapper.updateMenu()
    local status = YZSwapper.watcher:isEnabled() and "ACTIVE" or "DISABLED"
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
