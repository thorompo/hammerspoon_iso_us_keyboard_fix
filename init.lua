-- ============================================================
-- UTILITY HOTKEYS
-- ============================================================

-- Double-tap Cmd+Q to Quit Apps
local quitModal = hs.hotkey.modal.new('cmd','q')
function quitModal:entered()
    hs.alert.show("      Quit?\nPress again", 1)
    hs.timer.doAfter(1, function() quitModal:exit() end)
end
quitModal:bind('cmd', 'q', function()
    local app = hs.application.frontmostApplication()
    if app then app:kill() end
end)
quitModal:bind('', 'escape', function() quitModal:exit() end)

-- Hungarian special characters (í / Í)
hs.hotkey.bind({"ctrl", "alt"}, "i", function()
    hs.eventtap.keyStrokes("í")
end)

hs.hotkey.bind({"shift", "ctrl", "alt"}, "i", function()
    hs.eventtap.keyStrokes("Í")
end)

-- Reload Hammerspoon Config
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)

-- Map Cmd+Shift+V to open Spotlight Clipboard (Cmd+Space then Cmd+4)
hs.hotkey.bind({"cmd", "shift"}, "v", function()
    hs.eventtap.keyStroke({"cmd"}, "space", 0) -- open spotlight
    hs.timer.doAfter(0.15, function()
        hs.eventtap.keyStroke({"cmd"}, "4", 0)
    end)
end)

hs.hotkey.bind({"ctrl"}, "v", function()
    hs.eventtap.keyStroke({"cmd"}, "space", 0) -- open spotlight
    hs.timer.doAfter(0.15, function()
        hs.eventtap.keyStroke({"cmd"}, "4", 0)
    end)
end)


-- ============================================================
-- MOUSE JIGGLER
-- ============================================================
local idleThreshold = 100 -- seconds
local checkInterval = 10  -- seconds

local function doJiggle()
    local currentPos = hs.mouse.getAbsolutePosition()
    if currentPos then
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, {x=currentPos.x+30, y=currentPos.y}):post()
        hs.timer.doAfter(3.2, function()
            hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, currentPos):post()
        end)
    end
end

local function checkIdle()
    if hs.host.idleTime() > idleThreshold then
        doJiggle()
    end
end

hs.timer.doEvery(checkInterval, checkIdle)

-- ============================================================
-- CMD+TAB: RÖVID NYOMÁS -> ELŐZŐ ABLAK | HOSSZÚ -> MISSION CONTROL
-- ============================================================
local tabPressTimer = nil
local longPressDelay = 0.2 -- Másodperc
local inMissionControl = false

-- Egy "figyelő", ami biztosítja, hogy a script ne zavarodjon össze,
-- ha véletlenül egérrel, Esc-vel, Enterrel vagy Szóközzel lépsz ki a Mission Controlból.
local mcStateWatcher = hs.eventtap.new({
    hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.keyDown
}, function(e)
    if inMissionControl then
        if e:getType() == hs.eventtap.event.types.leftMouseDown then
            inMissionControl = false
        elseif e:getType() == hs.eventtap.event.types.keyDown then
            local code = e:getKeyCode()
            -- 53 = Esc, 36 = Return, 49 = Space
            if code == 53 or code == 36 or code == 49 then
                inMissionControl = false
            end
        end
    end
    return false -- Sosem blokkoljuk ezeket a gombokat/kattintásokat
end)
mcStateWatcher:start()

cmdTabTap = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp}, function(event)
    local flags = event:getFlags()
    local keyCode = event:getKeyCode()
    local isAutoRepeat = event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) ~= 0

    -- Csak a Tab billentyűt (48) figyeljük
    if keyCode == 48 then
        if event:getType() == hs.eventtap.event.types.keyDown then
            -- Ha csak a Cmd van lenyomva
            if flags.cmd and not flags.ctrl and not flags.alt and not flags.shift then
                if isAutoRepeat then return true end 
                
                -- Stopper indítása
                tabPressTimer = hs.timer.doAfter(longPressDelay, function()
                    -- HOSSZÚ NYOMÁS: Mission Control indítása
                    hs.application.launchOrFocus("Mission Control")
                    inMissionControl = true -- Feljegyezzük, hogy bent vagyunk!
                    tabPressTimer = nil 
                end)
                
                return true -- Elnyeljük a rendszertől a gombnyomást
            end
            
        elseif event:getType() == hs.eventtap.event.types.keyUp then
            -- Ha a felengedéskor még fut a stopper -> RÖVID NYOMÁS
            if tabPressTimer then
                tabPressTimer:stop()
                tabPressTimer = nil
                
                if inMissionControl then
                    -- 1. ESET: Már a Mission Controlban vagyunk -> Kilépés (Escape szimulálása)
                    inMissionControl = false
                    hs.eventtap.keyStroke({}, "escape")
                else
                    -- 2. ESET: Normál állapot -> Váltás az előző ablakra
                    local wins = hs.window.orderedWindows()
                    if wins and #wins > 1 then
                        local prevWin = wins[2]
                        local app = prevWin:application()
                        
                        if app then app:activate() end
                        prevWin:focus()
                    end
                end
                
                return true -- Elnyeljük a felengedést is
            end
        end
    end
    
    return false
end)

cmdTabTap:start()


-- ============================================================
-- INITIALIZATION
-- ============================================================
hs.alert.show("Hammerspoon Config Loaded")
