local theme = dofile("system/theme.lua")
local network = dofile("lib/network.lua")
local config = dofile("system/config.lua")

local w, h = term.getSize()
local settings = config.load()

local username = settings.username or "User"
local messages = {}
local inputText = ""
local cursorPos = 1
local scrollOffset = 0
local targetId = nil

local protocol = "craftos_chat"

network.init()
if network.isOpen() then
    rednet.host(protocol, username)
end

local function addMessage(sender, text, isSystem)
    table.insert(messages, {
        sender = sender,
        text = text,
        time = textutils.formatTime(os.time(), true),
        isSystem = isSystem or false,
    })
    
    if #messages > 100 then
        table.remove(messages, 1)
    end
end

addMessage("System", "Welcome to CraftOS Chat!", true)
addMessage("System", "Username: " .. username, true)
addMessage("System", "Type /help for commands", true)

if network.isOpen() then
    addMessage("System", "Network online (ID: " .. os.getComputerID() .. ")", true)
else
    addMessage("System", "No modem detected - offline mode", true)
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
    term.write("Chat - " .. username)
    
    if network.isOpen() then
        term.setCursorPos(w - 8, 1)
        term.setBackgroundColor(colors.green)
        term.write(" ONLINE ")
    else
        term.setCursorPos(w - 9, 1)
        term.setBackgroundColor(colors.red)
        term.write(" OFFLINE ")
    end
    
    local msgAreaH = h - 4
    local msgStartY = 2
    
    term.setBackgroundColor(t.window_bg)
    for i = 0, msgAreaH - 1 do
        local msgIndex = #messages - scrollOffset - (msgAreaH - 1 - i)
        local msg = messages[msgIndex]
        
        term.setCursorPos(1, msgStartY + i + 1)
        
        if msg then
            if msg.isSystem then
                term.setTextColor(colors.gray)
                term.write("[" .. msg.time .. "] " .. msg.text)
            else
                term.setTextColor(colors.gray)
                term.write("[" .. msg.time .. "] ")
                
                if msg.sender == username then
                    term.setTextColor(colors.lightBlue)
                else
                    term.setTextColor(colors.lime)
                end
                term.write(msg.sender .. ": ")
                
                term.setTextColor(t.window_fg)
                term.write(msg.text)
            end
        end
        
        local cx, cy = term.getCursorPos()
        term.write(string.rep(" ", w - cx + 1))
    end
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(1, h - 2)
    term.write(string.rep("-", w))
    
    term.setBackgroundColor(t.input_bg)
    term.setTextColor(t.input_fg)
    term.setCursorPos(1, h - 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(1, h - 1)
    
    local prompt = username .. "> "
    term.setTextColor(t.accent)
    term.write(prompt)
    
    term.setTextColor(t.input_fg)
    local maxInput = w - #prompt
    local displayText = inputText
    if #displayText > maxInput then
        displayText = string.sub(displayText, #displayText - maxInput + 1)
    end
    term.write(displayText)
    
    term.setCursorPos(#prompt + math.min(cursorPos - 1, maxInput - 1) + 1, h - 1)
    term.setCursorBlink(true)
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(1, h)
    local status = "/help for commands | /msg ID for private | /quit to exit"
    if targetId then
        status = "Private message to ID: " .. targetId .. " | /reply to switch back"
    end
    term.write(status)
end

local function sendMessage(text)
    if text == "" then return end
    
    if string.sub(text, 1, 1) == "/" then
        local parts = {}
        for part in text:gmatch("%S+") do
            table.insert(parts, part)
        end
        
        local cmd = parts[1]:lower()
        
        if cmd == "/help" then
            addMessage("System", "Commands:", true)
            addMessage("System", "/help - Show this help", true)
            addMessage("System", "/msg ID - Send private message", true)
            addMessage("System", "/reply - Switch back to broadcast", true)
            addMessage("System", "/name NAME - Change username", true)
            addMessage("System", "/id - Show your computer ID", true)
            addMessage("System", "/clear - Clear messages", true)
            addMessage("System", "/quit - Exit chat", true)
            
        elseif cmd == "/msg" then
            if parts[2] then
                targetId = tonumber(parts[2])
                addMessage("System", "Now messaging ID: " .. targetId, true)
            else
                addMessage("System", "Usage: /msg <computer_id>", true)
            end
            
        elseif cmd == "/reply" then
            targetId = nil
            addMessage("System", "Switched to broadcast mode", true)
            
        elseif cmd == "/name" then
            if parts[2] then
                username = parts[2]
                addMessage("System", "Username changed to: " .. username, true)
            else
                addMessage("System", "Usage: /name <new_name>", true)
            end
            
        elseif cmd == "/id" then
            addMessage("System", "Your ID: " .. os.getComputerID(), true)
            
        elseif cmd == "/clear" then
            messages = {}
            addMessage("System", "Messages cleared", true)
            
        elseif cmd == "/quit" then
            return false
        else
            addMessage("System", "Unknown command: " .. cmd, true)
        end
    else
        addMessage(username, text)
        
        if network.isOpen() then
            local msg = {
                sender = username,
                text = text,
                fromId = os.getComputerID(),
            }
            
            if targetId then
                network.send(targetId, msg, protocol)
            else
                network.broadcast(msg, protocol)
            end
        end
    end
    
    return true
end

draw()

local function messageListener()
    while true do
        if network.isOpen() then
            local senderId, message, msgProtocol = rednet.receive(protocol, 0.5)
            if senderId and message then
                if message.sender and message.text then
                    if message.fromId ~= os.getComputerID() then
                        addMessage(message.sender, message.text)
                    end
                end
            end
        else
            sleep(1)
        end
    end
end

local function inputHandler()
    while true do
        local event = table.pack(os.pullEvent())
        
        if event[1] == "char" then
            inputText = string.sub(inputText, 1, cursorPos - 1) .. event[2] .. string.sub(inputText, cursorPos)
            cursorPos = cursorPos + 1
            draw()
            
        elseif event[1] == "key" then
            local key = event[2]
            
            if key == keys.enter then
                if inputText ~= "" then
                    local continue = sendMessage(inputText)
                    inputText = ""
                    cursorPos = 1
                    draw()
                    if not continue then break end
                end
                
            elseif key == keys.backspace then
                if cursorPos > 1 then
                    inputText = string.sub(inputText, 1, cursorPos - 2) .. string.sub(inputText, cursorPos)
                    cursorPos = cursorPos - 1
                    draw()
                end
                
            elseif key == keys.delete then
                if cursorPos <= #inputText then
                    inputText = string.sub(inputText, 1, cursorPos - 1) .. string.sub(inputText, cursorPos + 1)
                    draw()
                end
                
            elseif key == keys.left then
                if cursorPos > 1 then cursorPos = cursorPos - 1 end
                draw()
            elseif key == keys.right then
                if cursorPos <= #inputText then cursorPos = cursorPos + 1 end
                draw()
            elseif key == keys.home then
                cursorPos = 1
                draw()
            elseif key == keys["end"] then
                cursorPos = #inputText + 1
                draw()
            elseif key == keys.up then
                scrollOffset = math.min(scrollOffset + 1, math.max(0, #messages - 5))
                draw()
            elseif key == keys.down then
                scrollOffset = math.max(0, scrollOffset - 1)
                draw()
            end
            
        elseif event[1] == "mouse_scroll" then
            if event[2] == -1 then
                scrollOffset = math.min(scrollOffset + 1, math.max(0, #messages - 5))
            else
                scrollOffset = math.max(0, scrollOffset - 1)
            end
            draw()
        end
    end
end

parallel.waitForAny(inputHandler, messageListener)
