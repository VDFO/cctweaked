local theme = dofile("system/theme.lua")
local config = dofile("system/config.lua")
local kernel = dofile("system/kernel.lua")
local events = dofile("system/events.lua")
local draw = dofile("lib/draw.lua")

local desktop = {}

desktop.windows = {}
desktop.nextWinId = 1
desktop.focusedWinId = nil
desktop.dragging = nil
desktop.startMenuOpen = false
desktop.screenW, desktop.screenH = term.getSize()
desktop.taskbarY = desktop.screenH
desktop.desktopH = desktop.screenH - 1
desktop.monitor = nil
desktop.monitorWindow = nil

desktop.programs = {
    {name = "Terminal",     icon = "T",  path = "programs/terminal.lua"},
    {name = "Files",        icon = "F",  path = "programs/filemanager.lua"},
    {name = "Editor",       icon = "E",  path = "programs/editor.lua"},
    {name = "Task Manager", icon = "M",  path = "programs/taskmanager.lua"},
    {name = "Settings",     icon = "S",  path = "programs/settings.lua"},
    {name = "Paint",        icon = "P",  path = "programs/paint.lua"},
    {name = "Redstone",     icon = "R",  path = "programs/redstone.lua"},
    {name = "Clock",        icon = "C",  path = "programs/clock.lua"},
    {name = "Calculator",   icon = "=",  path = "programs/calculator.lua"},
    {name = "Chat",         icon = "@",  path = "programs/chat.lua"},
    {name = "Chess",        icon = "#",  path = "programs/chess.lua"},
    {name = "Monitor",      icon = "D",  path = "programs/monitor.lua"},
}

function desktop.getKernel()
    return kernel
end

function desktop.getFocusedProcess()
    if desktop.focusedWinId and desktop.windows[desktop.focusedWinId] then
        return desktop.windows[desktop.focusedWinId].processId
    end
    return nil
end

function desktop.detectMonitor()
    local settings = config.load()
    
    if settings.monitorMode == "off" then
        desktop.monitor = nil
        return
    end
    
    if settings.monitorName and peripheral.isPresent(settings.monitorName) then
        desktop.monitor = peripheral.wrap(settings.monitorName)
    else
        desktop.monitor = peripheral.find("monitor")
    end
    
    if desktop.monitor then
        desktop.monitor.setTextScale(settings.textScale or 1.0)
    end
end

function desktop.drawDesktop()
    local t = theme.get()
    term.setBackgroundColor(t.desktop_bg)
    term.clear()
    
    local logo = "CraftOS Desktop"
    local lx = math.floor((desktop.screenW - #logo) / 2) + 1
    local ly = math.floor(desktop.desktopH / 2) - 1
    
    term.setTextColor(t.desktop_fg)
    term.setCursorPos(lx, ly)
    term.write(logo)
    
    term.setCursorPos(lx, ly + 2)
    local hint = "Click Start to open programs"
    term.write(hint)
end

function desktop.drawTaskbar()
    local t = theme.get()
    local y = desktop.taskbarY
    
    draw.box(1, y, desktop.screenW, 1, t.taskbar_fg, t.taskbar_bg)
    
    draw.text(1, y, " Start ", t.taskbar_fg, t.accent)
    
    local clock = textutils.formatTime(os.time(), true)
    draw.text(desktop.screenW - #clock, y, clock, t.taskbar_fg, t.taskbar_bg)
    
    local tabX = 8
    for id, win in pairs(desktop.windows) do
        if tabX + #win.title + 3 > desktop.screenW - 10 then break end
        
        local tabBg = (id == desktop.focusedWinId) and t.taskbar_active or t.taskbar_bg
        local tabFg = (id == desktop.focusedWinId) and t.taskbar_fg or t.taskbar_fg
        local label = " " .. win.title .. " "
        if #label > 12 then label = string.sub(label, 1, 12) .. " " end
        
        draw.text(tabX, y, label, tabFg, tabBg)
        win._tabX = tabX
        win._tabW = #label
        tabX = tabX + #label + 1
    end
end

function desktop.drawStartMenu()
    if not desktop.startMenuOpen then return end
    
    local t = theme.get()
    local menuW = 20
    local menuH = #desktop.programs + 2
    local menuX = 1
    local menuY = desktop.taskbarY - menuH
    
    draw.box(menuX, menuY, menuW, menuH, t.menu_fg, t.menu_bg)
    draw.border(menuX, menuY, menuW, menuH, t.border_color)
    
    draw.text(menuX + 1, menuY, " Programs ", t.menu_fg, t.menu_bg)
    
    for i, prog in ipairs(desktop.programs) do
        local py = menuY + i
        draw.text(menuX + 1, py, " " .. prog.icon .. " " .. prog.name, t.menu_fg, t.menu_bg)
    end
end

function desktop.redraw()
    desktop.drawDesktop()
    desktop.drawTaskbar()
    if desktop.startMenuOpen then
        desktop.drawStartMenu()
    end
end

function desktop.getWindowAt(x, y)
    if y == desktop.taskbarY then
        return nil
    end
    
    local sorted = {}
    for id, win in pairs(desktop.windows) do
        if win.visible and not win.minimized then
            table.insert(sorted, win)
        end
    end
    table.sort(sorted, function(a, b) return (a.zOrder or 0) > (b.zOrder or 0) end)
    
    for _, win in ipairs(sorted) do
        if x >= win.x and x < win.x + win.w and y >= win.y and y < win.y + win.h then
            return win
        end
    end
    return nil
end

function desktop.createWindow(title, w, h)
    local id = desktop.nextWinId
    desktop.nextWinId = desktop.nextWinId + 1
    
    local x = math.floor((desktop.screenW - w) / 2) + 1
    local y = math.max(1, math.floor((desktop.desktopH - h) / 2))
    
    if x < 1 then x = 1 end
    if y < 1 then y = 1 end
    if w > desktop.screenW then w = desktop.screenW end
    if h > desktop.desktopH then h = desktop.desktopH end
    
    local clientW = w - 2
    local clientH = h - 3
    
    local winObj = window.create(term.current(), x, y, w, h, false)
    local clientObj = window.create(winObj, 2, 2, clientW, clientH, true)
    
    local win = {
        id = id,
        title = title,
        x = x,
        y = y,
        w = w,
        h = h,
        clientW = clientW,
        clientH = clientH,
        window = winObj,
        clientWindow = clientObj,
        processId = nil,
        minimized = false,
        visible = true,
        zOrder = id,
    }
    
    desktop.windows[id] = win
    desktop.focusWindow(id)
    
    return win
end

function desktop.drawWindowChrome(win)
    local t = theme.get()
    local isActive = (win.id == desktop.focusedWinId)
    
    win.window.setVisible(false)
    
    local oldTerm = term.redirect(win.window)
    
    local bg = t.window_bg
    local fg = t.window_fg
    local borderC = t.border_color
    
    term.setBackgroundColor(bg)
    term.clear()
    
    for i = 0, win.h - 1 do
        term.setCursorPos(1, i + 1)
        term.setBackgroundColor(borderC)
        term.write(" ")
        term.setCursorPos(win.w, i + 1)
        term.write(" ")
        term.setBackgroundColor(bg)
    end
    
    term.setBackgroundColor(borderC)
    term.setCursorPos(1, win.h)
    term.write(string.rep(" ", win.w))
    
    local titleBg = isActive and t.titlebar_bg or t.titlebar_inactive_bg
    local titleFg = isActive and t.titlebar_fg or t.titlebar_inactive_fg
    
    term.setBackgroundColor(titleBg)
    term.setTextColor(titleFg)
    term.setCursorPos(2, 1)
    
    local maxTitleLen = win.w - 6
    local displayTitle = win.title
    if #displayTitle > maxTitleLen then
        displayTitle = string.sub(displayTitle, 1, maxTitleLen - 3) .. "..."
    end
    term.write(displayTitle)
    
    local closeX = win.w - 1
    term.setCursorPos(closeX - 3, 1)
    term.write("[_]")
    term.setCursorPos(closeX, 1)
    term.write("X")
    
    term.redirect(oldTerm)
    win.window.setVisible(true)
    win.window.redraw()
end

function desktop.focusWindow(id)
    if not desktop.windows[id] then return end
    
    local oldFocused = desktop.focusedWinId
    desktop.focusedWinId = id
    
    local maxZ = 0
    for _, win in pairs(desktop.windows) do
        if win.zOrder and win.zOrder > maxZ then maxZ = win.zOrder end
    end
    desktop.windows[id].zOrder = maxZ + 1
    
    if oldFocused and oldFocused ~= id and desktop.windows[oldFocused] then
        desktop.drawWindowChrome(desktop.windows[oldFocused])
    end
    
    desktop.drawWindowChrome(desktop.windows[id])
    desktop.drawTaskbar()
end

function desktop.closeWindow(id)
    local win = desktop.windows[id]
    if not win then return end
    
    if win.processId then
        kernel.kill(win.processId)
    end
    
    win.window.setVisible(false)
    desktop.windows[id] = nil
    
    if desktop.focusedWinId == id then
        desktop.focusedWinId = nil
        local maxZ = 0
        local topId = nil
        for wid, w in pairs(desktop.windows) do
            if w.visible and not w.minimized and (w.zOrder or 0) > maxZ then
                maxZ = w.zOrder or 0
                topId = wid
            end
        end
        if topId then
            desktop.focusWindow(topId)
        end
    end
    
    desktop.redraw()
end

function desktop.minimizeWindow(id)
    local win = desktop.windows[id]
    if not win then return end
    
    win.minimized = true
    win.window.setVisible(false)
    
    if desktop.focusedWinId == id then
        desktop.focusedWinId = nil
        local maxZ = 0
        local topId = nil
        for wid, w in pairs(desktop.windows) do
            if w.visible and not w.minimized and (w.zOrder or 0) > maxZ then
                maxZ = w.zOrder or 0
                topId = wid
            end
        end
        if topId then
            desktop.focusWindow(topId)
        end
    end
    
    desktop.redraw()
end

function desktop.restoreWindow(id)
    local win = desktop.windows[id]
    if not win then return end
    
    win.minimized = false
    win.window.setVisible(true)
    desktop.focusWindow(id)
    desktop.redraw()
end

function desktop.startDrag(id, x, y)
    local win = desktop.windows[id]
    if not win then return end
    
    desktop.dragging = {
        id = id,
        offsetX = x - win.x,
        offsetY = y - win.y,
    }
end

function desktop.isDragging()
    return desktop.dragging ~= nil
end

function desktop.dragWindow(x, y)
    if not desktop.dragging then return end
    
    local win = desktop.windows[desktop.dragging.id]
    if not win then
        desktop.dragging = nil
        return
    end
    
    local newX = x - desktop.dragging.offsetX
    local newY = y - desktop.dragging.offsetY
    
    if newX < 1 then newX = 1 end
    if newY < 1 then newY = 1 end
    if newX + win.w - 1 > desktop.screenW then newX = desktop.screenW - win.w + 1 end
    if newY + win.h - 1 > desktop.desktopH then newY = desktop.desktopH - win.h + 1 end
    
    local oldX, oldY = win.x, win.y
    
    if newX ~= oldX or newY ~= oldY then
        win.window.setVisible(false)
        
        local t = theme.get()
        local nativeTerm = term.native()
        local currentTerm = term.current()
        
        if desktop.monitor then
            nativeTerm = desktop.monitor
        end
        
        for i = 0, win.h - 1 do
            nativeTerm.setCursorPos(oldX, oldY + i)
            nativeTerm.setBackgroundColor(t.desktop_bg)
            nativeTerm.setTextColor(t.desktop_fg)
            nativeTerm.write(string.rep(" ", win.w))
        end
        
        win.window.reposition(newX, newY)
        win.x = newX
        win.y = newY
        
        win.window.setVisible(true)
        win.window.redraw()
    end
end

function desktop.endDrag()
    desktop.dragging = nil
end

function desktop.handleDesktopClick(x, y, button)
    if y == desktop.taskbarY then
        if x >= 1 and x <= 7 then
            desktop.startMenuOpen = not desktop.startMenuOpen
            desktop.redraw()
            return
        end
        
        for id, win in pairs(desktop.windows) do
            if win._tabX and x >= win._tabX and x < win._tabX + (win._tabW or 0) then
                if win.minimized then
                    desktop.restoreWindow(id)
                else
                    desktop.focusWindow(id)
                end
                return
            end
        end
        
        return
    end
    
    if desktop.startMenuOpen then
        local t = theme.get()
        local menuW = 20
        local menuH = #desktop.programs + 2
        local menuX = 1
        local menuY = desktop.taskbarY - menuH
        
        if x >= menuX and x < menuX + menuW and y >= menuY and y < menuY + menuH then
            local progIndex = y - menuY
            if progIndex >= 1 and progIndex <= #desktop.programs then
                local prog = desktop.programs[progIndex]
                desktop.startMenuOpen = false
                desktop.redraw()
                desktop.launchProgram(prog)
                return
            end
        end
        
        desktop.startMenuOpen = false
        desktop.redraw()
    end
end

function desktop.launchProgram(prog)
    local win = desktop.createWindow(prog.name, 30, 15)
    
    local processFunc = function()
        local oldTerm = term.redirect(win.clientWindow)
        local ok, err = pcall(function()
            dofile(prog.path)
        end)
        term.redirect(oldTerm)
        
        if not ok and err and err ~= "Terminated" then
            local oldTerm2 = term.redirect(win.clientWindow)
            term.clear()
            term.setCursorPos(1, 1)
            term.setTextColor(colors.red)
            print("Error: " .. tostring(err))
            term.setTextColor(colors.white)
            print("\nPress any key to close...")
            term.redirect(oldTerm2)
            os.pullEvent("char")
        end
    end
    
    local pid = kernel.spawn(prog.name, processFunc, win)
    win.processId = pid
end

function desktop.handlePeripheralEvent(event)
    local oldMonitor = desktop.monitor
    desktop.detectMonitor()
    
    if oldMonitor and not desktop.monitor then
        term.redirect(term.native())
        desktop.screenW, desktop.screenH = term.getSize()
        desktop.taskbarY = desktop.screenH
        desktop.desktopH = desktop.screenH - 1
        desktop.redraw()
    end
    
    if desktop.monitor and not oldMonitor then
        term.redirect(desktop.monitor)
        desktop.screenW, desktop.screenH = desktop.monitor.getSize()
        desktop.taskbarY = desktop.screenH
        desktop.desktopH = desktop.screenH - 1
        desktop.redraw()
    end
end

function desktop.handleMonitorTouch(event)
    local monitorName = event[2]
    local x, y = event[3], event[4]
    
    if desktop.monitor and peripheral.getName(desktop.monitor) == monitorName then
        events.routeEvent({"mouse_click", 1, x, y})
    end
end

function desktop.run()
    local settings = config.load()
    if settings.theme then
        theme.apply(settings.theme)
    end
    
    desktop.detectMonitor()
    
    if desktop.monitor then
        desktop.monitor.setTextScale(settings.textScale or 1.0)
        desktop.monitor.setTextColor(colors.white)
        desktop.monitor.setBackgroundColor(colors.black)
        desktop.monitor.clear()
        
        local mw, mh = desktop.monitor.getSize()
        desktop.monitor.setCursorPos(math.floor((mw - 15) / 2) + 1, math.floor(mh / 2))
        desktop.monitor.setTextColor(colors.lightBlue)
        desktop.monitor.write("CraftOS Desktop")
        desktop.monitor.setCursorPos(math.floor((mw - 10) / 2) + 1, math.floor(mh / 2) + 2)
        desktop.monitor.setTextColor(colors.white)
        desktop.monitor.write("Loading...")
        
        term.redirect(desktop.monitor)
        
        desktop.screenW, desktop.screenH = desktop.monitor.getSize()
        desktop.taskbarY = desktop.screenH
        desktop.desktopH = desktop.screenH - 1
        
        local nativeTerm = term.native()
        nativeTerm.setBackgroundColor(colors.black)
        nativeTerm.clear()
        nativeTerm.setCursorPos(1, 1)
        nativeTerm.setTextColor(colors.lightBlue)
        nativeTerm.write("CraftOS Desktop")
        nativeTerm.setCursorPos(1, 3)
        nativeTerm.setTextColor(colors.lime)
        nativeTerm.write("Desktop is running on monitor")
        nativeTerm.setCursorPos(1, 5)
        nativeTerm.setTextColor(colors.gray)
        nativeTerm.write("Monitor: " .. (settings.monitorName or "auto-detected"))
        nativeTerm.setCursorPos(1, 7)
        nativeTerm.setTextColor(colors.white)
        nativeTerm.write("Press Ctrl+T to terminate")
    end
    
    desktop.redraw()
    
    events.setDesktop(desktop)
    
    local function eventLoop()
        while kernel.running do
            local event = table.pack(os.pullEventRaw())
            
            if event[1] == "mouse_up" then
                desktop.endDrag()
            else
                events.routeEvent(event)
            end
            
            kernel.resumeReadyProcesses()
            
            if event[1] == "timer" then
                desktop.drawTaskbar()
            end
        end
    end
    
    local function clockTicker()
        while kernel.running do
            os.sleep(1)
            desktop.drawTaskbar()
        end
    end
    
    os.startTimer(1)
    
    parallel.waitForAll(eventLoop, clockTicker)
end

desktop.run()
