local theme = dofile("system/theme.lua")
local widget = dofile("lib/widget.lua")

local w, h = term.getSize()

local function getProcessList()
    local kernel = dofile("system/kernel.lua")
    return kernel.list()
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
    term.write("Task Manager")
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(1, 2)
    term.write(string.rep("-", w))
    
    term.setTextColor(t.window_fg)
    term.setCursorPos(2, 3)
    term.write("ID")
    term.setCursorPos(8, 3)
    term.write("Name")
    term.setCursorPos(w - 8, 3)
    term.write("State")
    
    term.setCursorPos(1, 4)
    term.write(string.rep("-", w))
    
    local processes = getProcessList()
    local y = 5
    for _, proc in ipairs(processes) do
        term.setCursorPos(2, y)
        term.setTextColor(t.window_fg)
        term.write(tostring(proc.id))
        
        term.setCursorPos(8, y)
        term.write(proc.name or "Unknown")
        
        term.setCursorPos(w - 8, y)
        if proc.state == "running" then
            term.setTextColor(colors.green)
        elseif proc.state == "waiting" then
            term.setTextColor(colors.yellow)
        elseif proc.state == "dead" then
            term.setTextColor(colors.red)
        else
            term.setTextColor(colors.gray)
        end
        term.write(proc.state)
        
        y = y + 1
    end
    
    term.setCursorPos(1, h - 1)
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.write(string.rep("-", w))
    
    term.setCursorPos(2, h)
    term.write(#processes .. " processes | Click to kill | Q to quit")
end

draw()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "mouse_click" then
        local x, y = event[3], event[4]
        if y >= 5 then
            local processes = getProcessList()
            local procIndex = y - 5 + 1
            if processes[procIndex] then
                local kernel = dofile("system/kernel.lua")
                kernel.kill(processes[procIndex].id)
                draw()
            end
        end
    elseif event[1] == "timer" then
        draw()
    elseif event[1] == "key" then
        if event[2] == keys.q then
            break
        elseif event[2] == keys.f5 then
            draw()
        end
    end
end
