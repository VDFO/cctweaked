local kernel = {}

kernel.processes = {}
kernel.nextId = 1
kernel.focused = nil
kernel.running = true

function kernel.spawn(name, func, window)
    local id = kernel.nextId
    kernel.nextId = kernel.nextId + 1
    
    local process = {
        id = id,
        name = name,
        coroutine = coroutine.create(func),
        window = window,
        state = "ready",
        filter = nil,
        eventQueue = {},
    }
    
    kernel.processes[id] = process
    
    if not kernel.focused then
        kernel.focused = id
    end
    
    return id
end

function kernel.kill(id)
    local process = kernel.processes[id]
    if process then
        process.state = "dead"
        kernel.processes[id] = nil
        
        if kernel.focused == id then
            kernel.focused = nil
            for pid, _ in pairs(kernel.processes) do
                kernel.focused = pid
                break
            end
        end
    end
end

function kernel.focus(id)
    if kernel.processes[id] then
        kernel.focused = id
        return true
    end
    return false
end

function kernel.list()
    local list = {}
    for id, process in pairs(kernel.processes) do
        table.insert(list, {
            id = id,
            name = process.name,
            state = process.state,
        })
    end
    return list
end

function kernel.sendToProcess(id, event)
    local process = kernel.processes[id]
    if process then
        table.insert(process.eventQueue, event)
        if process.state == "waiting" then
            process.state = "ready"
        end
    end
end

function kernel.sendToAll(event)
    for id, _ in pairs(kernel.processes) do
        kernel.sendToProcess(id, event)
    end
end

function kernel.resumeProcess(process)
    if process.state == "dead" then return end
    
    if #process.eventQueue == 0 then
        process.state = "waiting"
        return
    end
    
    local event = table.remove(process.eventQueue, 1)
    
    if process.filter and event[1] ~= process.filter then
        table.insert(process.eventQueue, 1, event)
        process.state = "waiting"
        return
    end
    
    process.state = "running"
    
    local ok, result = coroutine.resume(process.coroutine, table.unpack(event))
    
    if not ok then
        if result and result ~= "Terminated" then
            printError("Process " .. process.name .. " error: " .. tostring(result))
        end
        process.state = "dead"
        kernel.processes[process.id] = nil
        return
    end
    
    if coroutine.status(process.coroutine) == "dead" then
        process.state = "dead"
        kernel.processes[process.id] = nil
    else
        if result == "pullEvent" then
            process.filter = nil
            process.state = "waiting"
        else
            process.state = "ready"
        end
    end
end

function kernel.resumeReadyProcesses()
    for id, process in pairs(kernel.processes) do
        if process.state == "ready" then
            kernel.resumeProcess(process)
        end
    end
end

function kernel.run()
    kernel.running = true
    
    while kernel.running and next(kernel.processes) do
        kernel.resumeReadyProcesses()
        
        local hasWaiting = false
        for _, process in pairs(kernel.processes) do
            if process.state == "waiting" then
                hasWaiting = true
                break
            end
        end
        
        if hasWaiting then
            local event = table.pack(os.pullEventRaw())
            
            if event[1] == "terminate" then
                if kernel.focused and kernel.processes[kernel.focused] then
                    kernel.sendToProcess(kernel.focused, event)
                end
            else
                kernel.sendToAll(event)
            end
        end
    end
end

return kernel
