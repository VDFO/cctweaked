local events = {}

events.desktop = nil

function events.setDesktop(desktop)
    events.desktop = desktop
end

function events.routeEvent(event)
    local name = event[1]
    local desktop = events.desktop
    
    if not desktop then return end
    
    if name == "mouse_click" or name == "mouse_drag" or name == "mouse_scroll" then
        local button, x, y = event[2], event[3], event[4]
        
        if y == desktop.taskbarY then
            desktop.handleDesktopClick(x, y, button)
        else
            local activeProcess = desktop.getActiveProcess()
            if activeProcess then
                local kernel = desktop.getKernel()
                kernel.sendToProcess(activeProcess, event)
            end
        end
        
    elseif name == "key" or name == "char" or name == "key_up" then
        local activeProcess = desktop.getActiveProcess()
        if activeProcess then
            local kernel = desktop.getKernel()
            kernel.sendToProcess(activeProcess, event)
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
        local activeProcess = desktop.getActiveProcess()
        if activeProcess then
            kernel.sendToProcess(activeProcess, event)
        end
    end
end

return events
