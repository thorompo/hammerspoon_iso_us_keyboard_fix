-- Hit 0 to 0, Hit Fn+0 to í, Hit Shift+0 to Í
local eventtap = hs.eventtap
local eventTypes = hs.eventtap.event.types

YZSwapper = {}
local y_code = 16
local z_code = 6
local tab_code = 48
local cmd_code = 55 
local alt_code = 58 

-- The watcher monitors: keyDown, keyUp, keyRepeat, and flagsChanged
YZSwapper.watcher = eventtap.new({eventTypes.keyDown, eventTypes.keyUp, eventTypes.keyRepeat, eventTypes.flagsChanged}, function(event)
    local keyCode = event:getKeyCode()
    local flags = event:getFlags()
    local type = event:getType()
    local char = event:getCharacters()
    
    -- 1. Swap Y and Z keys
    -- We swap the keycode for all event types (down/up) to prevent "stuck" keys.
    if keyCode == y_code then
        event:setKeyCode(z_code)
        return false
    elseif keyCode == z_code then
        event:setKeyCode(y_code)
        return false
    end

    -- 2. CHARACTER REPLACEMENT LOGIC (í/Í key)
    -- This runs only for keyDown and keyRepeat events
    if type == eventTypes.keyDown or type == eventTypes.keyRepeat then
        if char == "í" or char == "Í" then
            -- If Fn is pressed, do nothing (keep original í or Í)
            if flags.fn then
                return false 
            end

            -- If capital Í (Shift is pressed), allow the original event
            if char == "Í" then
                return false
            end

            -- If lowercase í, replace it with 0
            if char == "í" then
                hs.eventtap.keyStrokes("0")
                return true
            end
        end
    end
    
    return false
end)
-- Create a menu switch
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
