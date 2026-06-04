local theme = dofile("system/theme.lua")
local widget = dofile("lib/widget.lua")

local currentPath = ""
local selectedIndex = 1
local scrollOffset = 0
local clipboard = nil
local clipboardAction = nil

local w, h = term.getSize()

local function getFiles()
    local files = {}
    table.insert(files, {name = "..", isDir = true, path = fs.getDir(currentPath)})
    
    if fs.isDir(currentPath) then
        local items = fs.list(currentPath)
        table.sort(items, function(a, b)
            local aDir = fs.isDir(fs.combine(currentPath, a))
            local bDir = fs.isDir(fs.combine(currentPath, b))
            if aDir ~= bDir then return aDir end
            return a:lower() < b:lower()
        end)
        
        for _, item in ipairs(items) do
            local fullPath = fs.combine(currentPath, item)
            table.insert(files, {
                name = item,
                isDir = fs.isDir(fullPath),
                path = fullPath,
                size = fs.getSize(fullPath),
            })
        end
    end
    return files
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
    local pathDisplay = currentPath == "" and "/" or currentPath
    if #pathDisplay > w - 4 then
        pathDisplay = "..." .. string.sub(pathDisplay, #pathDisplay - w + 7)
    end
    term.write(pathDisplay)
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(1, 2)
    term.write(string.rep("-", w))
    
    local listY = 3
    local listH = h - 5
    local files = getFiles()
    
    for i = 0, listH - 1 do
        local fi = i + 1 + scrollOffset
        local file = files[fi]
        
        term.setCursorPos(1, listY + i)
        
        if file then
            if fi == selectedIndex then
                term.setBackgroundColor(t.accent)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(t.window_bg)
                term.setTextColor(t.window_fg)
            end
            
            local icon = file.isDir and "[D] " or "[F] "
            local name = icon .. file.name
            local sizeStr = ""
            if not file.isDir and file.size then
                sizeStr = " (" .. file.size .. "B)"
            end
            
            local display = name .. sizeStr
            if #display > w then display = string.sub(display, 1, w) end
            term.write(display .. string.rep(" ", w - #display))
        else
            term.setBackgroundColor(t.window_bg)
            term.write(string.rep(" ", w))
        end
    end
    
    term.setBackgroundColor(t.button_bg)
    term.setTextColor(t.button_fg)
    term.setCursorPos(1, h - 1)
    term.write(string.rep(" ", w))
    
    local buttons = {"Copy", "Move", "Del", "Rename", "New"}
    local btnX = 1
    for _, btn in ipairs(buttons) do
        term.setCursorPos(btnX, h - 1)
        term.write("[" .. btn .. "]")
        btnX = btnX + #btn + 3
    end
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(1, h)
    local status = #files .. " items"
    if clipboard then
        status = status .. " | Clipboard: " .. clipboard
    end
    term.write(status .. string.rep(" ", w - #status))
end

local function doCopy(path)
    clipboard = path
    clipboardAction = "copy"
end

local function doMove(path)
    clipboard = path
    clipboardAction = "move"
end

local function doPaste()
    if not clipboard then return end
    
    local name = fs.getName(clipboard)
    local dest = fs.combine(currentPath, name)
    
    if clipboardAction == "copy" then
        fs.copy(clipboard, dest)
    elseif clipboardAction == "move" then
        fs.move(clipboard, dest)
        clipboard = nil
        clipboardAction = nil
    end
end

local function doDelete(path)
    if fs.exists(path) then
        fs.delete(path)
    end
end

local function doRename(path)
    local oldName = fs.getName(path)
    term.setCursorPos(1, h)
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(t.window_fg)
    term.write("New name: ")
    term.write(string.rep(" ", w - 11))
    term.setCursorPos(12, h)
    
    local newName = read()
    if newName and newName ~= "" then
        local newPath = fs.combine(currentPath, newName)
        fs.move(path, newPath)
    end
end

local function doNewFolder()
    term.setCursorPos(1, h)
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(t.window_fg)
    term.write("Folder name: ")
    term.write(string.rep(" ", w - 14))
    term.setCursorPos(15, h)
    
    local name = read()
    if name and name ~= "" then
        local path = fs.combine(currentPath, name)
        fs.makeDir(path)
    end
end

draw()

while true do
    local event = table.pack(os.pullEvent())
    local files = getFiles()
    local listH = h - 5
    
    if event[1] == "mouse_click" then
        local x, y = event[3], event[4]
        
        if y >= 3 and y < h - 2 then
            local fi = y - 3 + 1 + scrollOffset
            if files[fi] then
                selectedIndex = fi
                draw()
            end
        elseif y == h - 1 then
            local file = files[selectedIndex]
            if file then
                if x >= 1 and x <= 6 then
                    doCopy(file.path)
                elseif x >= 9 and x <= 14 then
                    doMove(file.path)
                elseif x >= 17 and x <= 21 then
                    doDelete(file.path)
                elseif x >= 24 and x <= 31 then
                    doRename(file.path)
                elseif x >= 34 and x <= 38 then
                    doNewFolder()
                end
                draw()
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
                        currentPath = file.path
                    end
                    selectedIndex = 1
                    scrollOffset = 0
                    draw()
                elseif clipboard and clipboardAction then
                    doPaste()
                    draw()
                end
            end
        elseif key == keys.c then
            local file = files[selectedIndex]
            if file then doCopy(file.path) end
            draw()
        elseif key == keys.v then
            doPaste()
            draw()
        elseif key == keys.delete then
            local file = files[selectedIndex]
            if file and file.name ~= ".." then
                doDelete(file.path)
                draw()
            end
        elseif key == keys.f5 then
            draw()
        end
    end
end
