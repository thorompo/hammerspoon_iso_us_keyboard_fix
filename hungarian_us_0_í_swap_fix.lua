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
    local isCitrix = isIgnoredAppActive()
    local keyCode = event:getKeyCode()
    local flags = event:getFlags()
    local type = event:getType()
    local char = event:getCharacters()

    -- --- CITRIX LOGIC (Swap Cmd/Alt) ---
    if isCitrix then
        if flags.cmd and keyCode == tab_code then return true end
        if keyCode == cmd_code then event:setKeyCode(alt_code)
        elseif keyCode == alt_code then event:setKeyCode(cmd_code) end
        return false
    end

    -- --- NORMAL MAC LOGIC ---
    
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
