local theme = dofile("system/theme.lua")
local fsutil = dofile("lib/filesystem.lua")

local w, h = term.getSize()
local notes = {}
local selectedNote = nil
local noteContent = {}
local cursorX = 1
local cursorY = 1
local scrollY = 0
local viewMode = "list"
local notesDir = "user/notes"

local function ensureDir()
    if not fs.isDir(notesDir) then
        fs.makeDir(notesDir)
    end
end

local function loadNotes()
    ensureDir()
    notes = {}
    for _, file in ipairs(fs.list(notesDir)) do
        if file:match("%.txt$") then
            local content = fsutil.readFile(notesDir .. "/" .. file) or ""
            table.insert(notes, {
                name = file:gsub("%.txt$", ""),
                content = content,
                size = #content,
            })
        end
    end
end

local function saveNote(name, content)
    ensureDir()
    fsutil.writeFile(notesDir .. "/" .. name .. ".txt", content)
end

local function deleteNote(name)
    fs.delete(notesDir .. "/" .. name .. ".txt")
end

local function drawList()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    term.write("Notes")
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(2, 3)
    term.write("Your Notes:")
    
    if #notes == 0 then
        term.setTextColor(colors.gray)
        term.setCursorPos(2, 5)
        term.write("No notes yet. Press N to create one.")
    else
        for i, note in ipairs(notes) do
            term.setCursorPos(2, 4 + i)
            if note == selectedNote then
                term.setBackgroundColor(colors.blue)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
            end
            local display = note.name
            if #display > w - 4 then display = string.sub(display, 1, w - 4) end
            term.write(display .. string.rep(" ", w - 2 - #display))
        end
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    term.setCursorPos(2, h)
    term.write("Click to open | N: new | D: delete | Q: quit")
end

local function drawEditor()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    if selectedNote then
        term.write("Notes - " .. selectedNote.name)
    else
        term.write("Notes - New Note")
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    
    for i = 1, h - 2 do
        local lineIndex = i + scrollY
        if noteContent[lineIndex] then
            term.setCursorPos(1, i + 1)
            local line = noteContent[lineIndex]
            if #line > w then line = string.sub(line, 1, w) end
            term.write(line .. string.rep(" ", w - #line))
        else
            term.setCursorPos(1, i + 1)
            term.write(string.rep(" ", w))
        end
    end
    
    term.setCursorPos(cursorX, cursorY - scrollY + 1)
    term.setCursorBlink(true)
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    term.setCursorPos(2, h)
    term.write("Type to edit | Ctrl+S: save | Esc: back | Q: quit")
end

local function openNote(note)
    selectedNote = note
    noteContent = {}
    cursorX = 1
    cursorY = 1
    scrollY = 0
    
    if note and note.content then
        for line in note.content:gmatch("[^\n]*") do
            table.insert(noteContent, line)
        end
    end
    
    if #noteContent == 0 then
        noteContent = {""}
    end
    
    viewMode = "editor"
    drawEditor()
end

local function newNote()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(2, h - 1)
    term.write("Note name: ")
    term.write(string.rep(" ", w - 12))
    term.setCursorPos(13, h - 1)
    local name = read()
    
    if name and name ~= "" then
        local note = {name = name, content = "", size = 0}
        table.insert(notes, note)
        openNote(note)
    else
        drawList()
    end
end

loadNotes()
drawList()

while true do
    local event = table.pack(os.pullEvent())
    
    if viewMode == "list" then
        if event[1] == "mouse_click" then
            local x, y = event[3], event[4]
            
            if y >= 5 and y < 5 + #notes then
                local noteIndex = y - 4
                if notes[noteIndex] then
                    openNote(notes[noteIndex])
                end
            end
            
        elseif event[1] == "key" then
            local key = event[2]
            
            if key == keys.q or key == keys.escape then
                break
            elseif key == keys.n then
                newNote()
            elseif key == keys.d then
                if selectedNote then
                    deleteNote(selectedNote.name)
                    loadNotes()
                    selectedNote = nil
                    drawList()
                end
            elseif key == keys.up then
                if selectedNote then
                    for i, note in ipairs(notes) do
                        if note == selectedNote and i > 1 then
                            selectedNote = notes[i - 1]
                            drawList()
                            break
                        end
                    end
                elseif #notes > 0 then
                    selectedNote = notes[#notes]
                    drawList()
                end
            elseif key == keys.down then
                if selectedNote then
                    for i, note in ipairs(notes) do
                        if note == selectedNote and i < #notes then
                            selectedNote = notes[i + 1]
                            drawList()
                            break
                        end
                    end
                elseif #notes > 0 then
                    selectedNote = notes[1]
                    drawList()
                end
            end
        end
        
    elseif viewMode == "editor" then
        if event[1] == "char" then
            local line = noteContent[cursorY]
            noteContent[cursorY] = string.sub(line, 1, cursorX - 1) .. event[2] .. string.sub(line, cursorX)
            cursorX = cursorX + 1
            drawEditor()
            
        elseif event[1] == "key" then
            local key = event[2]
            
            if key == keys.enter then
                local line = noteContent[cursorY]
                local before = string.sub(line, 1, cursorX - 1)
                local after = string.sub(line, cursorX)
                noteContent[cursorY] = before
                table.insert(noteContent, cursorY + 1, after)
                cursorY = cursorY + 1
                cursorX = 1
                drawEditor()
                
            elseif key == keys.backspace then
                if cursorX > 1 then
                    local line = noteContent[cursorY]
                    noteContent[cursorY] = string.sub(line, 1, cursorX - 2) .. string.sub(line, cursorX)
                    cursorX = cursorX - 1
                    drawEditor()
                elseif cursorY > 1 then
                    local prevLine = noteContent[cursorY - 1]
                    local currLine = noteContent[cursorY]
                    cursorX = #prevLine + 1
                    noteContent[cursorY - 1] = prevLine .. currLine
                    table.remove(noteContent, cursorY)
                    cursorY = cursorY - 1
                    drawEditor()
                end
                
            elseif key == keys.left then
                if cursorX > 1 then
                    cursorX = cursorX - 1
                    drawEditor()
                elseif cursorY > 1 then
                    cursorY = cursorY - 1
                    cursorX = #noteContent[cursorY] + 1
                    drawEditor()
                end
                
            elseif key == keys.right then
                if cursorX <= #noteContent[cursorY] then
                    cursorX = cursorX + 1
                    drawEditor()
                elseif cursorY < #noteContent then
                    cursorY = cursorY + 1
                    cursorX = 1
                    drawEditor()
                end
                
            elseif key == keys.up then
                if cursorY > 1 then
                    cursorY = cursorY - 1
                    cursorX = math.min(cursorX, #noteContent[cursorY] + 1)
                    if cursorY <= scrollY then scrollY = cursorY - 1 end
                    drawEditor()
                end
                
            elseif key == keys.down then
                if cursorY < #noteContent then
                    cursorY = cursorY + 1
                    cursorX = math.min(cursorX, #noteContent[cursorY] + 1)
                    if cursorY > scrollY + h - 2 then scrollY = cursorY - h + 2 end
                    drawEditor()
                end
                
            elseif key == keys.escape then
                viewMode = "list"
                selectedNote = nil
                loadNotes()
                drawList()
                
            elseif key == keys.q then
                break
                
            elseif key == keys.leftCtrl or key == keys.rightCtrl then
                local nextEvent = table.pack(os.pullEvent())
                if nextEvent[1] == "char" and nextEvent[2]:lower() == "s" then
                    if selectedNote then
                        local content = table.concat(noteContent, "\n")
                        saveNote(selectedNote.name, content)
                        selectedNote.content = content
                        term.setCursorPos(2, h)
                        term.setTextColor(colors.lime)
                        term.write(" Saved! ")
                        sleep(1)
                        drawEditor()
                    end
                end
            end
        end
    end
end
