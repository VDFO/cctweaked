local theme = dofile("system/theme.lua")
local config = dofile("system/config.lua")
local widget = dofile("lib/widget.lua")

local settings = config.load()
local selectedIndex = 1
local w, h = term.getSize()

local options = {
    {name = "Theme", key = "theme", values = {"default", "dark", "retro"}},
    {name = "Monitor Mode", key = "monitorMode", values = {"off", "mirror", "extend"}},
    {name = "Text Scale", key = "textScale", values = {0.5, 1.0, 1.5, 2.0}},
    {name = "Username", key = "username", editable = true},
}

local function getCurrentValueIndex(opt)
    local val = settings[opt.key]
    for i, v in ipairs(opt.values) do
        if v == val then return i end
    end
    return 1
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
    term.write("Settings")
    
    local y = 3
    for i, opt in ipairs(options) do
        local isSelected = (i == selectedIndex)
        
        if isSelected then
            term.setBackgroundColor(t.accent)
            term.setTextColor(colors.white)
        else
            term.setBackgroundColor(t.window_bg)
            term.setTextColor(t.window_fg)
        end
        
        term.setCursorPos(2, y)
        term.write(opt.name .. ": ")
        
        if opt.values then
            local vi = getCurrentValueIndex(opt)
            term.write("< " .. tostring(opt.values[vi]) .. " >")
        elseif opt.editable then
            term.write(tostring(settings[opt.key] or ""))
        end
        
        term.write(string.rep(" ", w - 2))
        y = y + 2
    end
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(2, h - 1)
    term.write("Use arrows to navigate, Enter to change")
    term.setCursorPos(2, h)
    term.write("Press S to save, Q to quit")
end

draw()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "key" then
        local key = event[2]
        
        if key == keys.up then
            selectedIndex = math.max(1, selectedIndex - 1)
            draw()
        elseif key == keys.down then
            selectedIndex = math.min(#options, selectedIndex + 1)
            draw()
        elseif key == keys.left or key == keys.right then
            local opt = options[selectedIndex]
            if opt.values then
                local vi = getCurrentValueIndex(opt)
                if key == keys.left then
                    vi = math.max(1, vi - 1)
                else
                    vi = math.min(#opt.values, vi + 1)
                end
                settings[opt.key] = opt.values[vi]
                draw()
            end
        elseif key == keys.enter then
            local opt = options[selectedIndex]
            if opt.editable then
                term.setCursorPos(2 + #opt.name + 2, 3 + (selectedIndex - 1) * 2)
                term.setBackgroundColor(t.input_bg)
                term.setTextColor(t.input_fg)
                term.write(string.rep(" ", w - #opt.name - 4))
                term.setCursorPos(2 + #opt.name + 2, 3 + (selectedIndex - 1) * 2)
                local val = read()
                if val then
                    settings[opt.key] = val
                end
                draw()
            end
        elseif key == keys.s then
            config.save(settings)
            term.setCursorPos(2, h)
            term.setBackgroundColor(t.success)
            term.setTextColor(colors.white)
            term.write(" Settings saved! ")
            sleep(1)
            draw()
        elseif key == keys.q then
            break
        end
        
    elseif event[1] == "mouse_click" then
        local x, y = event[3], event[4]
        for i, opt in ipairs(options) do
            local optY = 3 + (i - 1) * 2
            if y == optY then
                selectedIndex = i
                if opt.values then
                    local vi = getCurrentValueIndex(opt)
                    local valStr = tostring(opt.values[vi])
                    local valStart = 2 + #opt.name + 2
                    if x >= valStart and x < valStart + #valStr + 4 then
                        if x < valStart + 1 then
                            vi = math.max(1, vi - 1)
                        else
                            vi = math.min(#opt.values, vi + 1)
                        end
                        settings[opt.key] = opt.values[vi]
                    end
                end
                draw()
                break
            end
        end
    end
end
