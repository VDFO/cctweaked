local theme = dofile("system/theme.lua")
local config = dofile("system/config.lua")
local kernel = dofile("system/kernel.lua")
local events = dofile("system/events.lua")
local draw = dofile("lib/draw.lua")

local desktop = {}

desktop.tabs = {}
desktop.nextTabId = 1
desktop.activeTabId = nil
desktop.startMenuOpen = false
desktop.screenW, desktop.screenH = term.getSize()
desktop.taskbarY = desktop.screenH
desktop.desktopH = desktop.screenH - 1
desktop.monitor = nil

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

function desktop.getActiveProcess()
    if desktop.activeTabId and desktop.tabs[desktop.activeTabId] then
        return desktop.tabs[desktop.activeTabId].processId
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
    for id, tab in pairs(desktop.tabs) do
        if tabX + #tab.title + 3 > desktop.screenW - 10 then break end
        
        local tabBg = (id == desktop.activeTabId) and t.taskbar_active or t.taskbar_bg
        local tabFg = t.taskbar_fg
        local label = " " .. tab.title .. " "
        if #label > 12 then label = string.sub(label, 1, 12) .. " " end
        
        draw.text(tabX, y, label, tabFg, tabBg)
        tab._tabX = tabX
        tab._tabW = #label
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

function desktop.createTab(title, prog)
    local id = desktop.nextTabId
    desktop.nextTabId = desktop.nextTabId + 1
    
    local tab = {
        id = id,
        title = title,
        processId = nil,
        prog = prog,
    }
    
    desktop.tabs[id] = tab
    desktop.activateTab(id)
    
    return tab
end

function desktop.activateTab(id)
    if not desktop.tabs[id] then return end
    
    local oldActive = desktop.activeTabId
    desktop.activeTabId = id
    
    if oldActive and oldActive ~= id and desktop.tabs[oldActive] then
        local oldTab = desktop.tabs[oldActive]
        if oldTab.processId and kernel.processes[oldTab.processId] then
            kernel.processes[oldTab.processId].state = "waiting"
        end
    end
    
    local newTab = desktop.tabs[id]
    if newTab.processId and kernel.processes[newTab.processId] then
        kernel.processes[newTab.processId].state = "ready"
    end
    
    desktop.drawTaskbar()
end

function desktop.closeTab(id)
    local tab = desktop.tabs[id]
    if not tab then return end
    
    if tab.processId then
        kernel.kill(tab.processId)
    end
    
    desktop.tabs[id] = nil
    
    if desktop.activeTabId == id then
        desktop.activeTabId = nil
        local firstId = nil
        for tid, _ in pairs(desktop.tabs) do
            firstId = tid
            break
        end
        if firstId then
            desktop.activateTab(firstId)
        else
            desktop.redraw()
        end
    else
        desktop.drawTaskbar()
    end
end

function desktop.launchProgram(prog)
    local tab = desktop.createTab(prog.name, prog)
    
    local processFunc = function()
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        
        local ok, err = pcall(function()
            dofile(prog.path)
        end)
        
        if not ok and err and err ~= "Terminated" then
            term.clear()
            term.setCursorPos(1, 1)
            term.setTextColor(colors.red)
            print("Error: " .. tostring(err))
            term.setTextColor(colors.white)
            print("\nPress any key to close...")
            os.pullEvent("char")
        end
    end
    
    local pid = kernel.spawn(prog.name, processFunc, nil)
    tab.processId = pid
end

function desktop.handleDesktopClick(x, y, button)
    if y == desktop.taskbarY then
        if x >= 1 and x <= 7 then
            desktop.startMenuOpen = not desktop.startMenuOpen
            desktop.redraw()
            return
        end
        
        for id, tab in pairs(desktop.tabs) do
            if tab._tabX and x >= tab._tabX and x < tab._tabX + (tab._tabW or 0) then
                desktop.activateTab(id)
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
            
            events.routeEvent(event)
            
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
