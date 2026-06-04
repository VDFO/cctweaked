local theme = dofile("system/theme.lua")
local config = dofile("system/config.lua")
local widget = dofile("lib/widget.lua")

local w, h = term.getSize()
local settings = config.load()
local monitors = {}
local selectedIndex = 1
local mode = settings.monitorMode or "off"

local function detectMonitors()
    monitors = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.hasType(name, "monitor") then
            local mon = peripheral.wrap(name)
            table.insert(monitors, {
                name = name,
                width = mon.getSize(),
                height = select(2, mon.getSize()),
                textScale = mon.getTextScale and mon.getTextScale() or 1.0,
            })
        end
    end
end

local function draw()
    local t = theme.get()
    term.setBackgroundColor(t.window_bg)
    term.clear()
    
    term.setBackgroundColor(t.titlebar_bg)
    term.setTextColor(t.titlebar_fg)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    term.write("Monitor Configuration")
    
    detectMonitors()
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(t.window_fg)
    term.setCursorPos(2, 3)
    term.write("Detected Monitors:")
    
    if #monitors == 0 then
        term.setTextColor(colors.red)
        term.setCursorPos(2, 5)
        term.write("No monitors detected!")
        term.setTextColor(colors.gray)
        term.setCursorPos(2, 6)
        term.write("Connect a monitor via wired modem")
    else
        local y = 5
        for i, mon in ipairs(monitors) do
            local isSelected = (i == selectedIndex)
            
            if isSelected then
                term.setBackgroundColor(t.accent)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(t.window_bg)
                term.setTextColor(t.window_fg)
            end
            
            term.setCursorPos(2, y)
            term.write(string.format("%-15s", mon.name))
            
            term.setCursorPos(18, y)
            term.write(string.format("%dx%d", mon.width, mon.height))
            
            term.setCursorPos(28, y)
            term.write(string.format("Scale: %.1f", mon.textScale))
            
            y = y + 1
        end
    end
    
    local optY = math.max(10, 5 + #monitors + 2)
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(1, optY)
    term.write(string.rep("-", w))
    
    optY = optY + 1
    term.setTextColor(t.window_fg)
    term.setCursorPos(2, optY)
    term.write("Display Mode:")
    
    optY = optY + 1
    local modes = {"off", "mirror", "extend"}
    local modeLabels = {"Off", "Mirror Desktop", "Extended Display"}
    
    for i, m in ipairs(modes) do
        local isSelected = (mode == m)
        
        term.setCursorPos(4, optY)
        if isSelected then
            term.setBackgroundColor(t.accent)
            term.setTextColor(colors.white)
        else
            term.setBackgroundColor(t.button_bg)
            term.setTextColor(t.button_fg)
        end
        term.write(" " .. modeLabels[i] .. " ")
        optY = optY + 1
    end
    
    optY = optY + 1
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(t.window_fg)
    term.setCursorPos(2, optY)
    term.write("Text Scale:")
    
    optY = optY + 1
    local scales = {0.5, 1.0, 1.5, 2.0, 3.0, 5.0}
    for i, scale in ipairs(scales) do
        term.setCursorPos(4 + (i - 1) * 6, optY)
        term.setBackgroundColor(t.button_bg)
        term.setTextColor(t.button_fg)
        term.write(string.format(" %.1f ", scale))
    end
    
    optY = optY + 2
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(2, optY)
    term.write("Click to select | S to save | T to test | Q to quit")
end

local function testMonitor()
    if #monitors == 0 then return end
    
    local mon = peripheral.wrap(monitors[selectedIndex].name)
    if not mon then return end
    
    local oldTerm = term.current()
    term.redirect(mon)
    
    mon.setBackgroundColor(colors.blue)
    mon.clear()
    
    local mw, mh = mon.getSize()
    mon.setTextColor(colors.white)
    mon.setCursorPos(math.floor(mw / 2) - 5, math.floor(mh / 2))
    mon.write("Test Pattern")
    
    mon.setCursorPos(math.floor(mw / 2) - 8, math.floor(mh / 2) + 2)
    mon.write(string.format("Resolution: %dx%d", mw, mh))
    
    mon.setCursorPos(math.floor(mw / 2) - 8, math.floor(mh / 2) + 4)
    mon.write("Press any key...")
    
    os.pullEvent("key")
    
    term.redirect(oldTerm)
end

draw()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "mouse_click" then
        local x, y = event[3], event[4]
        
        if y >= 5 and y < 5 + #monitors then
            selectedIndex = y - 5 + 1
            draw()
        elseif event[2] == 1 then
            local optY = math.max(10, 5 + #monitors + 2) + 2
            if y >= optY and y < optY + 3 then
                local modes = {"off", "mirror", "extend"}
                mode = modes[y - optY + 1]
                draw()
            end
            
            local scaleOptY = math.max(10, 5 + #monitors + 2) + 6
            if y == scaleOptY then
                local scales = {0.5, 1.0, 1.5, 2.0, 3.0, 5.0}
                for i, scale in ipairs(scales) do
                    local sx = 4 + (i - 1) * 6
                    if x >= sx and x < sx + 5 then
                        if #monitors > 0 then
                            local mon = peripheral.wrap(monitors[selectedIndex].name)
                            if mon and mon.setTextScale then
                                mon.setTextScale(scale)
                            end
                        end
                        draw()
                        break
                    end
                end
            end
        end
        
    elseif event[1] == "key" then
        if event[2] == keys.s then
            settings.monitorMode = mode
            if #monitors > 0 then
                settings.monitorName = monitors[selectedIndex].name
            end
            config.save(settings)
            
            term.setCursorPos(2, h)
            term.setBackgroundColor(colors.green)
            term.setTextColor(colors.white)
            term.write(" Settings saved! ")
            sleep(1)
            draw()
            
        elseif event[2] == keys.t then
            testMonitor()
            draw()
            
        elseif event[2] == keys.q then
            break
        end
        
    elseif event[1] == "peripheral" or event[1] == "peripheral_detach" then
        draw()
    end
end
