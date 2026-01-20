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
    return app and ignoredApps[app:name()]
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
-- 3. PART: Main Event Handler
-- ============================================================
local eventtap = hs.eventtap
local eventTypes = hs.eventtap.event.types

YZSwapper = {}
local y_code = 16
local z_code = 6
local tab_code = 48
local cmd_code = 55 
local alt_code = 58 

YZSwapper.watcher = eventtap.new({eventTypes.keyDown, eventTypes.keyUp, eventTypes.keyRepeat, eventTypes.flagsChanged}, function(event)
    local isCitrix = isIgnoredAppActive()
    local keyCode = event:getKeyCode()
    local flags = event:getFlags()
    local type = event:getType()
    local char = event:getCharacters()

    -- ------------------------------------------------------------
    -- A: CITRIX LOGIC (Only runs when Citrix is active)
    -- ------------------------------------------------------------
    if isCitrix then
        -- Allow Cmd+Tab to work normally
        if flags.cmd and keyCode == tab_code then return true end
        
        -- Swap Cmd and Alt for Windows shortcuts
        if keyCode == cmd_code then 
            event:setKeyCode(alt_code)
        elseif keyCode == alt_code then 
            event:setKeyCode(cmd_code) 
        end
        
        -- EXIT HERE: Do not process Y/Z or í logic if in Citrix
        return false 
    end

    -- ------------------------------------------------------------
    -- B: NORMAL MAC LOGIC (Only runs when NOT in Citrix)
    -- ------------------------------------------------------------
    
    -- 1. Swap Y and Z keys (All event types to prevent sticking)
    if keyCode == y_code then
        event:setKeyCode(z_code)
        return false
    elseif keyCode == z_code then
        event:setKeyCode(y_code)
        return false
    end

    -- 2. CHARACTER REPLACEMENT LOGIC (í/Í key)
    if type == eventTypes.keyDown or type == eventTypes.keyRepeat then
        if char == "í" or char == "Í" then
            -- If Fn is pressed, keep original í/Í
            if flags.fn then
                return false 
            end

            -- If Shift+í (Capital Í), keep original Í
            if char == "Í" then
                return false
            end

            -- If lowercase í, replace with 0
            if char == "í" then
                hs.eventtap.keyStrokes("0")
                return true
            end
        end
    end
    
    return false
end)

-- ============================================================
-- 4. PART: Menubar Initialization
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

YZSwapper.watcher:start()
YZSwapper.updateMenu()
hs.alert.show("Keyboard Fixes Loaded")
