local history = {}
local historyIndex = 0
local scrollback = {}
local maxScrollback = 100

local w, h = term.getSize()

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

print("CraftOS Terminal")
print("Type 'help' for commands")
print("")

local function addToScrollback(text)
    for line in text:gmatch("[^\n]*") do
        table.insert(scrollback, line)
    end
    while #scrollback > maxScrollback do
        table.remove(scrollback, 1)
    end
end

local function redraw()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    local startLine = math.max(1, #scrollback - h + 2)
    for i = 1, h - 1 do
        local lineIndex = startLine + i - 1
        if scrollback[lineIndex] then
            term.setCursorPos(1, i)
            term.setTextColor(colors.white)
            term.write(scrollback[lineIndex])
        end
    end
end

local function runCommand(cmd)
    addToScrollback("> " .. cmd)
    
    if cmd == "clear" then
        scrollback = {}
        redraw()
        return
    end
    
    if cmd == "history" then
        for i, h_cmd in ipairs(history) do
            addToScrollback(i .. ": " .. h_cmd)
        end
        redraw()
        return
    end
    
    local ok, err = pcall(function()
        shell.run(cmd)
    end)
    
    if not ok then
        addToScrollback("Error: " .. tostring(err))
    end
end

while true do
    term.setCursorPos(1, h)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.lime)
    term.write("> ")
    term.setTextColor(colors.white)
    
    local input = ""
    local cursorPos = 1
    local quit = false
    
    while true do
        term.setCursorPos(3 + cursorPos - 1, h)
        term.setCursorBlink(true)
        
        local event = table.pack(os.pullEvent())
        
        if event[1] == "char" then
            input = string.sub(input, 1, cursorPos - 1) .. event[2] .. string.sub(input, cursorPos)
            cursorPos = cursorPos + 1
            
            term.setCursorPos(3, h)
            term.write(input .. " ")
            
        elseif event[1] == "key" then
            local key = event[2]
            
            if key == keys.enter then
                term.setCursorBlink(false)
                addToScrollback("> " .. input)
                
                if input == "exit" or input == "quit" then
                    quit = true
                    break
                end
                
                if input ~= "" then
                    table.insert(history, input)
                    historyIndex = #history + 1
                    runCommand(input)
                end
                
                redraw()
                break
                
            elseif key == keys.backspace then
                if cursorPos > 1 then
                    input = string.sub(input, 1, cursorPos - 2) .. string.sub(input, cursorPos)
                    cursorPos = cursorPos - 1
                    
                    term.setCursorPos(3, h)
                    term.write(input .. " ")
                end
                
            elseif key == keys.delete then
                if cursorPos <= #input then
                    input = string.sub(input, 1, cursorPos - 1) .. string.sub(input, cursorPos + 1)
                    
                    term.setCursorPos(3, h)
                    term.write(input .. " ")
                end
                
            elseif key == keys.left then
                if cursorPos > 1 then
                    cursorPos = cursorPos - 1
                end
                
            elseif key == keys.right then
                if cursorPos <= #input then
                    cursorPos = cursorPos + 1
                end
                
            elseif key == keys.home then
                cursorPos = 1
                
            elseif key == keys["end"] then
                cursorPos = #input + 1
                
            elseif key == keys.up then
                if historyIndex > 1 then
                    historyIndex = historyIndex - 1
                    input = history[historyIndex]
                    cursorPos = #input + 1
                    
                    term.setCursorPos(3, h)
                    term.write(input .. string.rep(" ", w - 3 - #input))
                end
                
            elseif key == keys.down then
                if historyIndex < #history then
                    historyIndex = historyIndex + 1
                    input = history[historyIndex]
                    cursorPos = #input + 1
                    
                    term.setCursorPos(3, h)
                    term.write(input .. string.rep(" ", w - 3 - #input))
                elseif historyIndex == #history then
                    historyIndex = historyIndex + 1
                    input = ""
                    cursorPos = 1
                    
                    term.setCursorPos(3, h)
                    term.write(string.rep(" ", w - 3))
                end
            end
        end
    end
    
    if quit then
        break
    end
end
