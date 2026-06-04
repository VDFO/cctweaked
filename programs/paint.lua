local theme = dofile("system/theme.lua")

local w, h = term.getSize()
local canvasW = w - 6
local canvasH = h - 5
local canvas = {}
local currentColor = colors.white
local currentTool = "pencil"
local currentFile = nil

local colorPalette = {
    colors.white, colors.orange, colors.magenta, colors.lightBlue,
    colors.yellow, colors.lime, colors.pink, colors.gray,
    colors.lightGray, colors.cyan, colors.purple, colors.blue,
    colors.brown, colors.green, colors.red, colors.black,
}

local colorNames = {
    "White", "Orange", "Magenta", "LtBlue",
    "Yellow", "Lime", "Pink", "Gray",
    "LtGray", "Cyan", "Purple", "Blue",
    "Brown", "Green", "Red", "Black",
}

local tools = {"pencil", "line", "box", "fill", "eraser"}
local toolIndex = 1

local lineStartX = nil
local lineStartY = nil

for y = 1, canvasH do
    canvas[y] = {}
    for x = 1, canvasW do
        canvas[y][x] = colors.black
    end
end

local function drawCanvas()
    for y = 1, canvasH do
        term.setCursorPos(4, y + 2)
        for x = 1, canvasW do
            term.setBackgroundColor(canvas[y][x])
            term.write(" ")
        end
    end
end

local function drawUI()
    local t = theme.get()
    term.setBackgroundColor(t.window_bg)
    term.clear()
    
    term.setBackgroundColor(t.titlebar_bg)
    term.setTextColor(t.titlebar_fg)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    local title = "Paint"
    if currentFile then title = title .. " - " .. currentFile end
    term.write(title)
    
    term.setBackgroundColor(t.window_bg)
    term.setCursorPos(1, 2)
    term.setBackgroundColor(colors.gray)
    term.write("   ")
    for y = 1, canvasH do
        term.setCursorPos(1, y + 2)
        term.write("   ")
        term.setCursorPos(4 + canvasW, y + 2)
        term.write("   ")
    end
    term.setCursorPos(1, canvasH + 3)
    term.write(string.rep(" ", w))
    
    drawCanvas()
    
    local paletteY = canvasH + 4
    term.setBackgroundColor(t.window_bg)
    term.setCursorPos(1, paletteY)
    for i, color in ipairs(colorPalette) do
        term.setBackgroundColor(color)
        term.write("  ")
    end
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(t.window_fg)
    term.setCursorPos(1, paletteY + 1)
    term.write("Tool: " .. currentTool)
    
    term.setCursorPos(w - 10, paletteY + 1)
    term.write("Color: ")
    term.setBackgroundColor(currentColor)
    term.write("  ")
end

local function floodFill(x, y, targetColor, replacementColor)
    if x < 1 or x > canvasW or y < 1 or y > canvasH then return end
    if canvas[y][x] ~= targetColor then return end
    if targetColor == replacementColor then return end
    
    canvas[y][x] = replacementColor
    
    floodFill(x + 1, y, targetColor, replacementColor)
    floodFill(x - 1, y, targetColor, replacementColor)
    floodFill(x, y + 1, targetColor, replacementColor)
    floodFill(x, y - 1, targetColor, replacementColor)
end

local function drawLine(x1, y1, x2, y2, color)
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)
    local sx = x1 < x2 and 1 or -1
    local sy = y1 < y2 and 1 or -1
    local err = dx - dy
    
    while true do
        if x1 >= 1 and x1 <= canvasW and y1 >= 1 and y1 <= canvasH then
            canvas[y1][x1] = color
        end
        
        if x1 == x2 and y1 == y2 then break end
        
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x1 = x1 + sx
        end
        if e2 < dx then
            err = err + dx
            y1 = y1 + sy
        end
    end
end

local function drawBox(x1, y1, x2, y2, color)
    local minX, maxX = math.min(x1, x2), math.max(x1, x2)
    local minY, maxY = math.min(y1, y2), math.max(y1, y2)
    
    for x = minX, maxX do
        if x >= 1 and x <= canvasW then
            if minY >= 1 and minY <= canvasH then canvas[minY][x] = color end
            if maxY >= 1 and maxY <= canvasH then canvas[maxY][x] = color end
        end
    end
    for y = minY, maxY do
        if y >= 1 and y <= canvasH then
            if minX >= 1 and minX <= canvasW then canvas[y][minX] = color end
            if maxX >= 1 and maxX <= canvasW then canvas[y][maxX] = color end
        end
    end
end

local function saveFile(path)
    local lines = {}
    for y = 1, canvasH do
        local line = ""
        for x = 1, canvasW do
            line = line .. colors.toBlit(canvas[y][x])
        end
        table.insert(lines, line)
    end
    
    local file = fs.open(path, "w")
    if file then
        for _, line in ipairs(lines) do
            file.writeLine(line)
        end
        file.close()
        currentFile = path
        return true
    end
    return false
end

local function loadFile(path)
    if not fs.exists(path) then return false end
    
    local image = paintutils.loadImage(path)
    if not image then return false end
    
    for y = 1, math.min(#image, canvasH) do
        for x = 1, math.min(#image[y], canvasW) do
            canvas[y][x] = image[y][x]
        end
    end
    
    currentFile = path
    return true
end

drawUI()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "mouse_click" then
        local button, x, y = event[2], event[3], event[4]
        
        local paletteY = canvasH + 4
        if y == paletteY then
            local colorIndex = math.floor((x - 1) / 2) + 1
            if colorIndex >= 1 and colorIndex <= #colorPalette then
                currentColor = colorPalette[colorIndex]
                drawUI()
            end
        elseif x >= 4 and x < 4 + canvasW and y >= 3 and y < 3 + canvasH then
            local cx = x - 3
            local cy = y - 2
            
            if currentTool == "pencil" then
                canvas[cy][cx] = currentColor
                drawCanvas()
            elseif currentTool == "eraser" then
                canvas[cy][cx] = colors.black
                drawCanvas()
            elseif currentTool == "fill" then
                floodFill(cx, cy, canvas[cy][cx], currentColor)
                drawCanvas()
            elseif currentTool == "line" or currentTool == "box" then
                lineStartX = cx
                lineStartY = cy
            end
        end
        
    elseif event[1] == "mouse_drag" then
        local button, x, y = event[2], event[3], event[4]
        
        if x >= 4 and x < 4 + canvasW and y >= 3 and y < 3 + canvasH then
            local cx = x - 3
            local cy = y - 2
            
            if currentTool == "pencil" then
                canvas[cy][cx] = currentColor
                drawCanvas()
            elseif currentTool == "eraser" then
                canvas[cy][cx] = colors.black
                drawCanvas()
            end
        end
        
    elseif event[1] == "mouse_up" then
        local button, x, y = event[2], event[3], event[4]
        
        if lineStartX and (currentTool == "line" or currentTool == "box") then
            local cx = x - 3
            local cy = y - 2
            
            if cx >= 1 and cx <= canvasW and cy >= 1 and cy <= canvasH then
                if currentTool == "line" then
                    drawLine(lineStartX, lineStartY, cx, cy, currentColor)
                elseif currentTool == "box" then
                    drawBox(lineStartX, lineStartY, cx, cy, currentColor)
                end
                drawCanvas()
            end
            
            lineStartX = nil
            lineStartY = nil
        end
        
    elseif event[1] == "key" then
        local key = event[2]
        
        if key == keys.t then
            toolIndex = toolIndex % #tools + 1
            currentTool = tools[toolIndex]
            drawUI()
        elseif key == keys.s then
            local nextEvent = table.pack(os.pullEvent())
            if nextEvent[1] == "char" and nextEvent[2]:lower() == "s" then
                if currentFile then
                    saveFile(currentFile)
                    drawUI()
                else
                    term.setCursorPos(1, h)
                    term.write("Save as: ")
                    local name = read()
                    if name and name ~= "" then
                        saveFile(name)
                    end
                    drawUI()
                end
            end
        elseif key == keys.o then
            local nextEvent = table.pack(os.pullEvent())
            if nextEvent[1] == "char" and nextEvent[2]:lower() == "o" then
                term.setCursorPos(1, h)
                term.write("Open: ")
                local name = read()
                if name and name ~= "" then
                    loadFile(name)
                end
                drawUI()
            end
        elseif key == keys.n then
            local nextEvent = table.pack(os.pullEvent())
            if nextEvent[1] == "char" and nextEvent[2]:lower() == "n" then
                for y = 1, canvasH do
                    for x = 1, canvasW do
                        canvas[y][x] = colors.black
                    end
                end
                currentFile = nil
                drawUI()
            end
        elseif key == keys.q then
            break
        end
    end
end
