local theme = dofile("system/theme.lua")

local w, h = term.getSize()
local sides = {"top", "bottom", "left", "right", "front", "back"}
local outputs = {}
local selectedSide = 1
local selectedColor = 1

local bundledColors = {
    {name = "White",    color = colors.white},
    {name = "Orange",   color = colors.orange},
    {name = "Magenta",  color = colors.magenta},
    {name = "LtBlue",   color = colors.lightBlue},
    {name = "Yellow",   color = colors.yellow},
    {name = "Lime",     color = colors.lime},
    {name = "Pink",     color = colors.pink},
    {name = "Gray",     color = colors.gray},
    {name = "LtGray",   color = colors.lightGray},
    {name = "Cyan",     color = colors.cyan},
    {name = "Purple",   color = colors.purple},
    {name = "Blue",     color = colors.blue},
    {name = "Brown",    color = colors.brown},
    {name = "Green",    color = colors.green},
    {name = "Red",      color = colors.red},
    {name = "Black",    color = colors.black},
}

for _, side in ipairs(sides) do
    outputs[side] = {
        redstone = false,
        bundled = 0,
    }
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
    term.write("Redstone Controller")
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(1, 2)
    term.write(string.rep("-", w))
    
    term.setTextColor(t.window_fg)
    term.setCursorPos(2, 3)
    term.write("Side")
    term.setCursorPos(12, 3)
    term.write("Output")
    term.setCursorPos(22, 3)
    term.write("Input")
    term.setCursorPos(32, 3)
    term.write("Bundled")
    
    term.setCursorPos(1, 4)
    term.setTextColor(colors.gray)
    term.write(string.rep("-", w))
    
    local y = 5
    for i, side in ipairs(sides) do
        local isSelected = (i == selectedSide)
        
        if isSelected then
            term.setBackgroundColor(t.accent)
            term.setTextColor(colors.white)
        else
            term.setBackgroundColor(t.window_bg)
            term.setTextColor(t.window_fg)
        end
        
        term.setCursorPos(2, y)
        term.write(string.format("%-8s", side))
        
        term.setCursorPos(12, y)
        if outputs[side].redstone then
            term.setTextColor(colors.red)
            if isSelected then term.setBackgroundColor(t.accent) end
            term.write("HIGH")
        else
            term.setTextColor(colors.gray)
            if isSelected then term.setBackgroundColor(t.accent) end
            term.write("LOW ")
        end
        
        term.setCursorPos(22, y)
        local input = rs.getInput(side)
        if input then
            term.setTextColor(colors.lime)
            if isSelected then term.setBackgroundColor(t.accent) end
            term.write("HIGH")
        else
            term.setTextColor(colors.gray)
            if isSelected then term.setBackgroundColor(t.accent) end
            term.write("LOW ")
        end
        
        term.setCursorPos(32, y)
        local bundledOut = outputs[side].bundled
        if bundledOut > 0 then
            term.setTextColor(colors.yellow)
            if isSelected then term.setBackgroundColor(t.accent) end
            term.write("Active")
        else
            term.setTextColor(colors.gray)
            if isSelected then term.setBackgroundColor(t.accent) end
            term.write("None  ")
        end
        
        y = y + 1
    end
    
    y = y + 1
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(1, y)
    term.write(string.rep("-", w))
    
    y = y + 1
    term.setTextColor(t.window_fg)
    term.setCursorPos(2, y)
    term.write("Bundled Colors (click to toggle):")
    
    y = y + 1
    local side = sides[selectedSide]
    for i, bc in ipairs(bundledColors) do
        local isActive = colors.test(outputs[side].bundled, bc.color)
        
        term.setCursorPos(2, y)
        term.setBackgroundColor(bc.color)
        term.setTextColor(isActive and colors.white or colors.black)
        term.write(string.format(" %-6s ", bc.name))
        
        if isActive then
            term.setBackgroundColor(t.success)
            term.setTextColor(colors.white)
            term.write(" ON ")
        else
            term.setBackgroundColor(t.button_bg)
            term.setTextColor(t.button_fg)
            term.write(" OFF")
        end
        
        y = y + 1
        if y > h - 2 then break end
    end
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(2, h - 1)
    term.write("Up/Down: select side | Space: toggle output")
    term.setCursorPos(2, h)
    term.write("Click color to toggle bundled | Q to quit")
end

draw()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "key" then
        local key = event[2]
        
        if key == keys.up then
            selectedSide = math.max(1, selectedSide - 1)
            draw()
        elseif key == keys.down then
            selectedSide = math.min(#sides, selectedSide + 1)
            draw()
        elseif key == keys.space then
            local side = sides[selectedSide]
            outputs[side].redstone = not outputs[side].redstone
            rs.setOutput(side, outputs[side].redstone)
            draw()
        elseif key == keys.q then
            break
        end
        
    elseif event[1] == "mouse_click" then
        local x, y = event[3], event[4]
        
        if y >= 5 and y < 5 + #sides then
            selectedSide = y - 5 + 1
            draw()
        else
            local side = sides[selectedSide]
            local colorStartY = 12
            local colorIndex = y - colorStartY + 1
            
            if colorIndex >= 1 and colorIndex <= #bundledColors then
                local bc = bundledColors[colorIndex]
                if colors.test(outputs[side].bundled, bc.color) then
                    outputs[side].bundled = colors.subtract(outputs[side].bundled, bc.color)
                else
                    outputs[side].bundled = colors.combine(outputs[side].bundled, bc.color)
                end
                
                if peripheral.isPresent(side) then
                    local bundled = peripheral.wrap(side)
                    if bundled and bundled.setBundledOutput then
                        bundled.setBundledOutput("back", outputs[side].bundled)
                    end
                end
                
                draw()
            end
        end
        
    elseif event[1] == "redstone" then
        draw()
    end
end
