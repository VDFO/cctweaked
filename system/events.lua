local events = {}

events.desktop = nil

function events.setDesktop(desktop)
    events.desktop = desktop
end

function events.getWindowAt(x, y)
    if not events.desktop then return nil end
    return events.desktop.getWindowAt(x, y)
end

function events.translateToWindow(win, x, y)
    return x - win.x + 1, y - win.y - 1
end

function events.isInTitlebar(win, x, y)
    return y == win.y and x >= win.x and x < win.x + win.w
end

function events.isInCloseButton(win, x, y)
    return y == win.y and x == win.x + win.w - 1
end

function events.isInMinimizeButton(win, x, y)
    return y == win.y and x == win.x + win.w - 4
end

function events.routeEvent(event)
    local name = event[1]
    local desktop = events.desktop
    
    if not desktop then return end
    
    if name == "mouse_click" or name == "mouse_drag" or name == "mouse_scroll" then
        local button, x, y = event[2], event[3], event[4]
        local win = events.getWindowAt(x, y)
        
        if win then
            if events.isInCloseButton(win, x, y) and name == "mouse_click" then
                desktop.closeWindow(win.id)
            elseif events.isInMinimizeButton(win, x, y) and name == "mouse_click" then
                desktop.minimizeWindow(win.id)
            elseif events.isInTitlebar(win, x, y) and name == "mouse_click" then
                desktop.focusWindow(win.id)
                desktop.startDrag(win.id, x, y)
            elseif name == "mouse_drag" and desktop.isDragging() then
                desktop.dragWindow(x, y)
            elseif name == "mouse_click" and not events.isInTitlebar(win, x, y) then
                desktop.focusWindow(win.id)
                local lx, ly = events.translateToWindow(win, x, y)
                if win.processId then
                    local kernel = desktop.getKernel()
                    kernel.sendToProcess(win.processId, {name, button, lx, ly})
                end
            elseif name == "mouse_scroll" then
                local lx, ly = events.translateToWindow(win, x, y)
                if win.processId then
                    local kernel = desktop.getKernel()
                    kernel.sendToProcess(win.processId, {name, button, lx, ly})
                end
            end
        else
            desktop.handleDesktopClick(x, y, button)
        end
        
    elseif name == "key" or name == "char" or name == "key_up" then
        local focusedProcess = desktop.getFocusedProcess()
        if focusedProcess then
            local kernel = desktop.getKernel()
            kernel.sendToProcess(focusedProcess, event)
        end
        
    elseif name == "timer" then
        local kernel = events.desktop.getKernel()
        kernel.sendToAll(event)
        
    elseif name == "rednet_message" then
        local kernel = events.desktop.getKernel()
        kernel.sendToAll(event)
        
    elseif name == "peripheral" or name == "peripheral_detach" then
        events.desktop.handlePeripheralEvent(event)
        
    elseif name == "monitor_touch" then
        events.desktop.handleMonitorTouch(event)
        
    elseif name == "terminate" then
        local kernel = events.desktop.getKernel()
        local focusedProcess = desktop.getFocusedProcess()
        if focusedProcess then
            kernel.sendToProcess(focusedProcess, event)
        end
    end
end

return events
