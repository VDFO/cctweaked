local theme = dofile("system/theme.lua")

local w, h = term.getSize()

local function draw()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    term.write("System Information")
    
    local y = 3
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.lightBlue)
    term.setCursorPos(2, y)
    term.write("Computer ID: ")
    term.setTextColor(colors.white)
    term.write(tostring(os.getComputerID()))
    y = y + 2
    
    term.setTextColor(colors.lightBlue)
    term.setCursorPos(2, y)
    term.write("Label: ")
    term.setTextColor(colors.white)
    term.write(os.getComputerLabel() or "None")
    y = y + 2
    
    term.setTextColor(colors.lightBlue)
    term.setCursorPos(2, y)
    term.write("Uptime: ")
    term.setTextColor(colors.white)
    term.write(tostring(os.clock()) .. " seconds")
    y = y + 2
    
    term.setTextColor(colors.lightBlue)
    term.setCursorPos(2, y)
    term.write("Day: ")
    term.setTextColor(colors.white)
    term.write(tostring(os.day()))
    y = y + 2
    
    term.setTextColor(colors.lightBlue)
    term.setCursorPos(2, y)
    term.write("Free Space: ")
    term.setTextColor(colors.white)
    local free = fs.getFreeSpace("/")
    term.write(tostring(free) .. " bytes")
    y = y + 2
    
    term.setTextColor(colors.lightBlue)
    term.setCursorPos(2, y)
    term.write("Total Space: ")
    term.setTextColor(colors.white)
    local total = fs.getCapacity and fs.getCapacity("/") or "Unknown"
    term.write(tostring(total))
    y = y + 2
    
    term.setTextColor(colors.lightBlue)
    term.setCursorPos(2, y)
    term.write("Peripherals: ")
    term.setTextColor(colors.white)
    local peripherals = peripheral.getNames()
    if #peripherals > 0 then
        term.write(table.concat(peripherals, ", "))
    else
        term.write("None")
    end
    y = y + 2
    
    if _G._kernel then
        term.setTextColor(colors.lightBlue)
        term.setCursorPos(2, y)
        term.write("Running Processes: ")
        term.setTextColor(colors.white)
        local processes = _G._kernel.list()
        term.write(tostring(#processes))
        y = y + 2
    end
    
    term.setTextColor(colors.lightBlue)
    term.setCursorPos(2, y)
    term.write("Redstone: ")
    term.setTextColor(colors.white)
    local hasRedstone = false
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral.isPresent(side) then
            hasRedstone = true
            break
        end
    end
    term.write(hasRedstone and "Available" or "Not available")
    y = y + 2
    
    term.setTextColor(colors.lightBlue)
    term.setCursorPos(2, y)
    term.write("HTTP: ")
    term.setTextColor(colors.white)
    term.write(http and "Enabled" or "Disabled")
    y = y + 2
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    term.setCursorPos(2, h)
    term.write("Press any key to refresh | Q to quit")
end

draw()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "key" then
        if event[2] == keys.q or event[2] == keys.escape then
            break
        else
            draw()
        end
    end
end
