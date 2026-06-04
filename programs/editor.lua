local theme = dofile("system/theme.lua")

local lines = {""}
local cursorX = 1
local cursorY = 1
local scrollX = 0
local scrollY = 0
local currentFile = nil
local modified = false

local w, h = term.getSize()

local keywords = {
    "and", "break", "do", "else", "elseif", "end", "false", "for",
    "function", "if", "in", "local", "nil", "not", "or", "repeat",
    "return", "then", "true", "until", "while"
}

local function isKeyword(word)
    for _, kw in ipairs(keywords) do
        if word == kw then return true end
    end
    return false
end

local function drawLine(y, lineNum, text)
    local t = theme.get()
    term.setCursorPos(1, y)
    term.setBackgroundColor(t.window_bg)
    
    local lineNumStr = string.format("%3d ", lineNum)
    term.setTextColor(colors.gray)
    term.write(lineNumStr)
    
    local codeStart = 5
    local visibleText = string.sub(text, scrollX + 1, scrollX + w - codeStart)
    
    local i = 1
    while i <= #visibleText do
        local char = string.sub(visibleText, i, i)
        
        if char == '"' or char == "'" then
            term.setTextColor(colors.red)
            term.write(char)
            i = i + 1
            while i <= #visibleText do
                local c = string.sub(visibleText, i, i)
                term.write(c)
                i = i + 1
                if c == char then break end
            end
        elseif char == "-" and string.sub(visibleText, i, i + 1) == "--" then
            term.setTextColor(colors.green)
            term.write(string.sub(visibleText, i))
            break
        elseif char:match("[%a_]") then
            local word = ""
            local start = i
            while i <= #visibleText and string.sub(visibleText, i, i):match("[%a%d_]") do
                word = word .. string.sub(visibleText, i, i)
                i = i + 1
            end
            if isKeyword(word) then
                term.setTextColor(colors.blue)
            elseif word == "self" then
                term.setTextColor(colors.purple)
            else
                term.setTextColor(t.window_fg)
            end
            term.write(word)
        elseif char:match("%d") then
            term.setTextColor(colors.orange)
            while i <= #visibleText and string.sub(visibleText, i, i):match("%d") do
                term.write(string.sub(visibleText, i, i))
                i = i + 1
            end
        else
            term.setTextColor(t.window_fg)
            term.write(char)
            i = i + 1
        end
    end
    
    term.write(string.rep(" ", w - codeStart - #visibleText + 1))
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
    local title = currentFile or "Untitled"
    if modified then title = title .. " *" end
    term.write(title)
    
    local editorH = h - 1
    for i = 1, editorH do
        local lineIndex = i + scrollY
        if lines[lineIndex] then
            drawLine(i + 1, lineIndex, lines[lineIndex])
        else
            term.setCursorPos(1, i + 1)
            term.setBackgroundColor(t.window_bg)
            term.write(string.rep(" ", w))
        end
    end
    
    local cursorScreenX = cursorX - scrollX + 4
    local cursorScreenY = cursorY - scrollY + 1
    if cursorScreenX >= 5 and cursorScreenX <= w and cursorScreenY >= 2 and cursorScreenY <= h then
        term.setCursorPos(cursorScreenX, cursorScreenY)
        term.setCursorBlink(true)
    end
end

local function ensureVisible()
    local editorH = h - 1
    local editorW = w - 5
    
    if cursorY <= scrollY then
        scrollY = cursorY - 1
    elseif cursorY > scrollY + editorH then
        scrollY = cursorY - editorH
    end
    
    if cursorX <= scrollX then
        scrollX = cursorX - 1
    elseif cursorX > scrollX + editorW then
        scrollX = cursorX - editorW
    end
end

local function saveFile(path)
    local file = fs.open(path, "w")
    if file then
        for i, line in ipairs(lines) do
            file.writeLine(line)
        end
        file.close()
        currentFile = path
        modified = false
        return true
    end
    return false
end

local function loadFile(path)
    if not fs.exists(path) then return false end
    local file = fs.open(path, "r")
    if not file then return false end
    
    lines = {}
    local line = file.readLine()
    while line do
        table.insert(lines, line)
        line = file.readLine()
    end
    file.close()
    
    if #lines == 0 then lines = {""} end
    
    currentFile = path
    cursorX = 1
    cursorY = 1
    scrollX = 0
    scrollY = 0
    modified = false
    return true
end

draw()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "char" then
        local line = lines[cursorY]
        lines[cursorY] = string.sub(line, 1, cursorX - 1) .. event[2] .. string.sub(line, cursorX)
        cursorX = cursorX + 1
        modified = true
        ensureVisible()
        draw()
        
    elseif event[1] == "key" then
        local key = event[2]
        
        if key == keys.enter then
            local line = lines[cursorY]
            local before = string.sub(line, 1, cursorX - 1)
            local after = string.sub(line, cursorX)
            lines[cursorY] = before
            table.insert(lines, cursorY + 1, after)
            cursorY = cursorY + 1
            cursorX = 1
            modified = true
            ensureVisible()
            draw()
            
        elseif key == keys.backspace then
            if cursorX > 1 then
                local line = lines[cursorY]
                lines[cursorY] = string.sub(line, 1, cursorX - 2) .. string.sub(line, cursorX)
                cursorX = cursorX - 1
                modified = true
            elseif cursorY > 1 then
                local prevLine = lines[cursorY - 1]
                local currLine = lines[cursorY]
                cursorX = #prevLine + 1
                lines[cursorY - 1] = prevLine .. currLine
                table.remove(lines, cursorY)
                cursorY = cursorY - 1
                modified = true
            end
            ensureVisible()
            draw()
            
        elseif key == keys.delete then
            local line = lines[cursorY]
            if cursorX <= #line then
                lines[cursorY] = string.sub(line, 1, cursorX - 1) .. string.sub(line, cursorX + 1)
                modified = true
            elseif cursorY < #lines then
                local nextLine = lines[cursorY + 1]
                lines[cursorY] = line .. nextLine
                table.remove(lines, cursorY + 1)
                modified = true
            end
            ensureVisible()
            draw()
            
        elseif key == keys.left then
            if cursorX > 1 then
                cursorX = cursorX - 1
            elseif cursorY > 1 then
                cursorY = cursorY - 1
                cursorX = #lines[cursorY] + 1
            end
            ensureVisible()
            draw()
            
        elseif key == keys.right then
            if cursorX <= #lines[cursorY] then
                cursorX = cursorX + 1
            elseif cursorY < #lines then
                cursorY = cursorY + 1
                cursorX = 1
            end
            ensureVisible()
            draw()
            
        elseif key == keys.up then
            if cursorY > 1 then
                cursorY = cursorY - 1
                cursorX = math.min(cursorX, #lines[cursorY] + 1)
            end
            ensureVisible()
            draw()
            
        elseif key == keys.down then
            if cursorY < #lines then
                cursorY = cursorY + 1
                cursorX = math.min(cursorX, #lines[cursorY] + 1)
            end
            ensureVisible()
            draw()
            
        elseif key == keys.home then
            cursorX = 1
            ensureVisible()
            draw()
            
        elseif key == keys["end"] then
            cursorX = #lines[cursorY] + 1
            ensureVisible()
            draw()
            
        elseif key == keys.tab then
            local line = lines[cursorY]
            lines[cursorY] = string.sub(line, 1, cursorX - 1) .. "    " .. string.sub(line, cursorX)
            cursorX = cursorX + 4
            modified = true
            ensureVisible()
            draw()
        end
    end
    
    if event[1] == "key" and (event[2] == keys.leftCtrl or event[2] == keys.rightCtrl) then
        local nextEvent = table.pack(os.pullEvent())
        if nextEvent[1] == "char" then
            local char = nextEvent[2]:lower()
            
            if char == "s" then
                if currentFile then
                    saveFile(currentFile)
                else
                    term.setCursorPos(1, h)
                    term.write("Save as: ")
                    local name = read()
                    if name and name ~= "" then
                        saveFile(name)
                    end
                end
                draw()
                
            elseif char == "o" then
                term.setCursorPos(1, h)
                term.write("Open: ")
                local name = read()
                if name and name ~= "" then
                    loadFile(name)
                end
                draw()
                
            elseif char == "n" then
                lines = {""}
                cursorX = 1
                cursorY = 1
                scrollX = 0
                scrollY = 0
                currentFile = nil
                modified = false
                draw()
            end
        end
    end
end
