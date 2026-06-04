local modal = {}

local theme = dofile("system/theme.lua")

function modal.alert(title, message)
    local t = theme.get()
    local sw, sh = term.getSize()
    
    local msgLines = {}
    for line in message:gmatch("[^\n]+") do
        table.insert(msgLines, line)
    end
    if #msgLines == 0 then msgLines = {""} end
    
    local maxLine = 0
    for _, line in ipairs(msgLines) do
        if #line > maxLine then maxLine = #line end
    end
    
    local boxW = math.max(maxLine + 4, #title + 4, 20)
    local boxH = #msgLines + 5
    local boxX = math.floor((sw - boxW) / 2) + 1
    local boxY = math.floor((sh - boxH) / 2) + 1
    
    if boxX < 1 then boxX = 1 end
    if boxY < 1 then boxY = 1 end
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(t.window_fg)
    for i = 0, boxH - 1 do
        term.setCursorPos(boxX, boxY + i)
        term.write(string.rep(" ", boxW))
    end
    
    term.setBackgroundColor(t.titlebar_bg)
    term.setTextColor(t.titlebar_fg)
    term.setCursorPos(boxX, boxY)
    term.write(string.rep(" ", boxW))
    term.setCursorPos(boxX + 2, boxY)
    term.write(title)
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(t.window_fg)
    for i, line in ipairs(msgLines) do
        term.setCursorPos(boxX + 2, boxY + i + 1)
        term.write(line)
    end
    
    local btnText = " OK "
    local btnX = boxX + math.floor((boxW - #btnText) / 2)
    local btnY = boxY + boxH - 2
    
    term.setBackgroundColor(t.button_bg)
    term.setTextColor(t.button_fg)
    term.setCursorPos(btnX, btnY)
    term.write(btnText)
    
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        if x >= btnX and x < btnX + #btnText and y == btnY then
            break
        end
        local key = os.pullEvent("key")
        if key == keys.enter or key == keys.escape then
            break
        end
    end
end

function modal.confirm(title, message)
    local t = theme.get()
    local sw, sh = term.getSize()
    
    local msgLines = {}
    for line in message:gmatch("[^\n]+") do
        table.insert(msgLines, line)
    end
    if #msgLines == 0 then msgLines = {""} end
    
    local maxLine = 0
    for _, line in ipairs(msgLines) do
        if #line > maxLine then maxLine = #line end
    end
    
    local boxW = math.max(maxLine + 4, #title + 4, 24)
    local boxH = #msgLines + 5
    local boxX = math.floor((sw - boxW) / 2) + 1
    local boxY = math.floor((sh - boxH) / 2) + 1
    
    if boxX < 1 then boxX = 1 end
    if boxY < 1 then boxY = 1 end
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(t.window_fg)
    for i = 0, boxH - 1 do
        term.setCursorPos(boxX, boxY + i)
        term.write(string.rep(" ", boxW))
    end
    
    term.setBackgroundColor(t.titlebar_bg)
    term.setTextColor(t.titlebar_fg)
    term.setCursorPos(boxX, boxY)
    term.write(string.rep(" ", boxW))
    term.setCursorPos(boxX + 2, boxY)
    term.write(title)
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(t.window_fg)
    for i, line in ipairs(msgLines) do
        term.setCursorPos(boxX + 2, boxY + i + 1)
        term.write(line)
    end
    
    local yesText = " Yes "
    local noText = " No "
    local btnY = boxY + boxH - 2
    local yesX = boxX + math.floor(boxW / 4) - math.floor(#yesText / 2)
    local noX = boxX + math.floor(3 * boxW / 4) - math.floor(#noText / 2)
    
    term.setBackgroundColor(t.button_bg)
    term.setTextColor(t.button_fg)
    term.setCursorPos(yesX, btnY)
    term.write(yesText)
    term.setCursorPos(noX, btnY)
    term.write(noText)
    
    while true do
        local event = table.pack(os.pullEvent())
        if event[1] == "mouse_click" then
            local x, y = event[3], event[4]
            if y == btnY then
                if x >= yesX and x < yesX + #yesText then return true end
                if x >= noX and x < noX + #noText then return false end
            end
        elseif event[1] == "key" then
            if event[2] == keys.enter or event[2] == keys.y then return true end
            if event[2] == keys.n or event[2] == keys.escape then return false end
        end
    end
end

function modal.input(title, prompt, default)
    local t = theme.get()
    local sw, sh = term.getSize()
    default = default or ""
    
    local boxW = math.max(#prompt + 4, #title + 4, 30)
    local boxH = 6
    local boxX = math.floor((sw - boxW) / 2) + 1
    local boxY = math.floor((sh - boxH) / 2) + 1
    
    if boxX < 1 then boxX = 1 end
    if boxY < 1 then boxY = 1 end
    
    local inputW = boxW - 4
    local inputText = default
    local cursorPos = #inputText + 1
    
    local function drawDialog()
        term.setBackgroundColor(t.window_bg)
        term.setTextColor(t.window_fg)
        for i = 0, boxH - 1 do
            term.setCursorPos(boxX, boxY + i)
            term.write(string.rep(" ", boxW))
        end
        
        term.setBackgroundColor(t.titlebar_bg)
        term.setTextColor(t.titlebar_fg)
        term.setCursorPos(boxX, boxY)
        term.write(string.rep(" ", boxW))
        term.setCursorPos(boxX + 2, boxY)
        term.write(title)
        
        term.setBackgroundColor(t.window_bg)
        term.setTextColor(t.window_fg)
        term.setCursorPos(boxX + 2, boxY + 2)
        term.write(prompt)
        
        term.setBackgroundColor(t.input_bg)
        term.setTextColor(t.input_fg)
        term.setCursorPos(boxX + 2, boxY + 3)
        local displayText = inputText
        if #displayText > inputW then
            displayText = string.sub(displayText, #displayText - inputW + 1)
        end
        term.write(displayText .. string.rep(" ", inputW - #displayText))
        
        term.setCursorPos(boxX + 2 + math.min(cursorPos - 1, inputW - 1), boxY + 3)
        term.setCursorBlink(true)
        
        local okText = " OK "
        local okX = boxX + math.floor((boxW - #okText) / 2)
        local okY = boxY + boxH - 1
        term.setBackgroundColor(t.button_bg)
        term.setTextColor(t.button_fg)
        term.setCursorPos(okX, okY)
        term.write(okText)
    end
    
    drawDialog()
    
    while true do
        local event = table.pack(os.pullEvent())
        
        if event[1] == "char" then
            inputText = string.sub(inputText, 1, cursorPos - 1) .. event[2] .. string.sub(inputText, cursorPos)
            cursorPos = cursorPos + 1
            drawDialog()
            
        elseif event[1] == "key" then
            local key = event[2]
            if key == keys.enter then
                term.setCursorBlink(false)
                return inputText
            elseif key == keys.escape then
                term.setCursorBlink(false)
                return nil
            elseif key == keys.backspace then
                if cursorPos > 1 then
                    inputText = string.sub(inputText, 1, cursorPos - 2) .. string.sub(inputText, cursorPos)
                    cursorPos = cursorPos - 1
                    drawDialog()
                end
            elseif key == keys.delete then
                if cursorPos <= #inputText then
                    inputText = string.sub(inputText, 1, cursorPos - 1) .. string.sub(inputText, cursorPos + 1)
                    drawDialog()
                end
            elseif key == keys.left then
                if cursorPos > 1 then
                    cursorPos = cursorPos - 1
                    drawDialog()
                end
            elseif key == keys.right then
                if cursorPos <= #inputText then
                    cursorPos = cursorPos + 1
                    drawDialog()
                end
            elseif key == keys.home then
                cursorPos = 1
                drawDialog()
            elseif key == keys["end"] then
                cursorPos = #inputText + 1
                drawDialog()
            end
            
        elseif event[1] == "mouse_click" then
            local x, y = event[3], event[4]
            local okText = " OK "
            local okX = boxX + math.floor((boxW - #okText) / 2)
            local okY = boxY + boxH - 1
            if x >= okX and x < okX + #okText and y == okY then
                term.setCursorBlink(false)
                return inputText
            end
        end
    end
end

function modal.fileDialog(title, startPath, mode)
    local t = theme.get()
    local sw, sh = term.getSize()
    local currentPath = startPath or ""
    local selectedFile = nil
    
    local boxW = math.min(sw - 2, 40)
    local boxH = math.min(sh - 2, 16)
    local boxX = math.floor((sw - boxW) / 2) + 1
    local boxY = math.floor((sh - boxH) / 2) + 1
    
    local listX = boxX + 2
    local listY = boxY + 3
    local listW = boxW - 4
    local listH = boxH - 6
    
    local scrollOffset = 0
    local selectedIndex = 1
    local fileName = ""
    
    local function getFiles()
        local files = {}
        table.insert(files, {name = "..", isDir = true})
        
        if fs.isDir(currentPath) then
            local items = fs.list(currentPath)
            table.sort(items)
            for _, item in ipairs(items) do
                local fullPath = fs.combine(currentPath, item)
                table.insert(files, {name = item, isDir = fs.isDir(fullPath)})
            end
        end
        return files
    end
    
    local function draw()
        term.setBackgroundColor(t.window_bg)
        term.setTextColor(t.window_fg)
        for i = 0, boxH - 1 do
            term.setCursorPos(boxX, boxY + i)
            term.write(string.rep(" ", boxW))
        end
        
        term.setBackgroundColor(t.titlebar_bg)
        term.setTextColor(t.titlebar_fg)
        term.setCursorPos(boxX, boxY)
        term.write(string.rep(" ", boxW))
        term.setCursorPos(boxX + 2, boxY)
        term.write(title)
        
        term.setBackgroundColor(t.window_bg)
        term.setTextColor(colors.gray)
        term.setCursorPos(boxX + 2, boxY + 1)
        local pathDisplay = currentPath == "" and "/" or currentPath
        if #pathDisplay > listW then pathDisplay = "..." .. string.sub(pathDisplay, #pathDisplay - listW + 4) end
        term.write(pathDisplay)
        
        local files = getFiles()
        for i = 0, listH - 1 do
            local fi = i + 1 + scrollOffset
            local file = files[fi]
            term.setCursorPos(listX, listY + i)
            
            if file then
                if fi == selectedIndex then
                    term.setBackgroundColor(t.accent)
                    term.setTextColor(colors.white)
                else
                    term.setBackgroundColor(t.window_bg)
                    term.setTextColor(t.window_fg)
                end
                
                local icon = file.isDir and "[D] " or "    "
                local name = icon .. file.name
                if #name > listW then name = string.sub(name, 1, listW) end
                term.write(name .. string.rep(" ", listW - #name))
            else
                term.setBackgroundColor(t.window_bg)
                term.write(string.rep(" ", listW))
            end
        end
        
        if mode == "save" then
            term.setBackgroundColor(t.window_bg)
            term.setTextColor(t.window_fg)
            term.setCursorPos(boxX + 2, boxY + boxH - 3)
            term.write("Name: ")
            term.setBackgroundColor(t.input_bg)
            term.setTextColor(t.input_fg)
            local inputW = listW - 7
            local displayFN = fileName
            if #displayFN > inputW then displayFN = string.sub(displayFN, #displayFN - inputW + 1) end
            term.write(displayFN .. string.rep(" ", inputW - #displayFN))
        end
        
        local okText = mode == "save" and " Save " or " Open "
        local cancelText = " Cancel "
        local btnY = boxY + boxH - 1
        local okX = boxX + math.floor(boxW / 3)
        local cancelX = boxX + math.floor(2 * boxW / 3)
        
        term.setBackgroundColor(t.button_bg)
        term.setTextColor(t.button_fg)
        term.setCursorPos(okX, btnY)
        term.write(okText)
        term.setCursorPos(cancelX, btnY)
        term.write(cancelText)
    end
    
    draw()
    
    while true do
        local event = table.pack(os.pullEvent())
        local files = getFiles()
        
        if event[1] == "mouse_click" then
            local x, y = event[3], event[4]
            
            if y >= listY and y < listY + listH then
                local fi = y - listY + 1 + scrollOffset
                if files[fi] then
                    selectedIndex = fi
                    if files[fi].isDir then
                        if files[fi].name == ".." then
                            currentPath = fs.getDir(currentPath)
                        else
                            currentPath = fs.combine(currentPath, files[fi].name)
                        end
                        selectedIndex = 1
                        scrollOffset = 0
                    else
                        if mode == "save" then
                            fileName = files[fi].name
                        else
                            selectedFile = fs.combine(currentPath, files[fi].name)
                        end
                    end
                    draw()
                end
            end
            
            local btnY = boxY + boxH - 1
            local okX = boxX + math.floor(boxW / 3)
            local cancelX = boxX + math.floor(2 * boxW / 3)
            local okText = mode == "save" and " Save " or " Open "
            local cancelText = " Cancel "
            
            if y == btnY then
                if x >= okX and x < okX + #okText then
                    if mode == "save" and fileName ~= "" then
                        return fs.combine(currentPath, fileName)
                    elseif mode == "open" and selectedFile then
                        return selectedFile
                    end
                elseif x >= cancelX and x < cancelX + #cancelText then
                    return nil
                end
            end
            
        elseif event[1] == "mouse_scroll" then
            local dir = event[2]
            if dir == -1 and scrollOffset > 0 then
                scrollOffset = scrollOffset - 1
                draw()
            elseif dir == 1 and scrollOffset + listH < #files then
                scrollOffset = scrollOffset + 1
                draw()
            end
            
        elseif event[1] == "key" then
            local key = event[2]
            if key == keys.up then
                selectedIndex = math.max(1, selectedIndex - 1)
                if selectedIndex <= scrollOffset then scrollOffset = selectedIndex - 1 end
                draw()
            elseif key == keys.down then
                selectedIndex = math.min(#files, selectedIndex + 1)
                if selectedIndex > scrollOffset + listH then scrollOffset = selectedIndex - listH end
                draw()
            elseif key == keys.enter then
                local file = files[selectedIndex]
                if file then
                    if file.isDir then
                        if file.name == ".." then
                            currentPath = fs.getDir(currentPath)
                        else
                            currentPath = fs.combine(currentPath, file.name)
                        end
                        selectedIndex = 1
                        scrollOffset = 0
                        draw()
                    else
                        if mode == "save" then
                            fileName = file.name
                            draw()
                        else
                            return fs.combine(currentPath, file.name)
                        end
                    end
                end
            elseif key == keys.escape then
                return nil
            end
            
        elseif event[1] == "char" and mode == "save" then
            fileName = fileName .. event[2]
            draw()
        elseif event[1] == "key" then
            if event[2] == keys.backspace and mode == "save" then
                fileName = string.sub(fileName, 1, #fileName - 1)
                draw()
            end
        end
    end
end

return modal
