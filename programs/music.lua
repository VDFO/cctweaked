local theme = dofile("system/theme.lua")

local w, h = term.getSize()
local tracks = {}
local currentTrack = nil
local isPlaying = false

local function findTracks()
    tracks = {}
    if fs.isDir("music") then
        for _, file in ipairs(fs.list("music")) do
            if file:match("%.dfpwm$") then
                table.insert(tracks, file)
            end
        end
    end
end

local function draw()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    term.write("Music Player")
    
    findTracks()
    
    if #tracks == 0 then
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.red)
        term.setCursorPos(2, 3)
        term.write("No .dfpwm files found in /music/")
        term.setTextColor(colors.gray)
        term.setCursorPos(2, 5)
        term.write("Place .dfpwm audio files in the /music/ folder")
    else
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.setCursorPos(2, 3)
        term.write("Tracks:")
        
        for i, track in ipairs(tracks) do
            term.setCursorPos(2, 4 + i)
            if track == currentTrack then
                if isPlaying then
                    term.setTextColor(colors.lime)
                    term.write("> " .. track)
                else
                    term.setTextColor(colors.yellow)
                    term.write("|| " .. track)
                end
            else
                term.setTextColor(colors.white)
                term.write("  " .. track)
            end
        end
        
        term.setTextColor(colors.gray)
        term.setCursorPos(2, 4 + #tracks + 2)
        term.write("Click to play/pause | Q to quit")
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    term.setCursorPos(2, h)
    term.write("Music Player | Q to quit")
end

local function playTrack(trackName)
    local speaker = peripheral.find("speaker")
    if not speaker then
        term.setCursorPos(2, h - 1)
        term.setTextColor(colors.red)
        term.write("No speaker found!")
        return
    end
    
    local path = "music/" .. trackName
    if not fs.exists(path) then return end
    
    currentTrack = trackName
    isPlaying = true
    draw()
    
    local file = fs.open(path, "rb")
    if not file then return end
    
    while isPlaying and currentTrack == trackName do
        local chunk = file.read(16 * 1024)
        if not chunk then break end
        
        while not speaker.playAudio(chunk) do
            local event = os.pullEvent("speaker_audio_empty")
        end
    end
    
    file.close()
    isPlaying = false
    draw()
end

draw()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "mouse_click" then
        local x, y = event[3], event[4]
        
        if y >= 5 and y < 5 + #tracks then
            local track = tracks[y - 4]
            if track then
                if currentTrack == track and isPlaying then
                    isPlaying = false
                else
                    currentTrack = track
                    isPlaying = true
                    draw()
                    
                    local speaker = peripheral.find("speaker")
                    if speaker then
                        parallel.waitForAny(
                            function() playTrack(track) end,
                            function()
                                while true do
                                    local ev = table.pack(os.pullEvent())
                                    if ev[1] == "mouse_click" then
                                        local my = ev[4]
                                        if my >= 5 and my < 5 + #tracks then
                                            local t = tracks[my - 4]
                                            if t and t ~= track then
                                                isPlaying = false
                                                return
                                            end
                                        end
                                    end
                                end
                            end
                        )
                    end
                end
                draw()
            end
        end
        
    elseif event[1] == "key" then
        if event[2] == keys.q or event[2] == keys.escape then
            isPlaying = false
            break
        end
    end
end
