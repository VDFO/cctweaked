local widget = {}

local theme = dofile("system/theme.lua")

function widget.button(x, y, w, text, active)
    local t = theme.get()
    local bg = active and t.button_hover or t.button_bg
    local fg = t.button_fg
    local label = text
    if #label > w - 2 then label = string.sub(label, 1, w - 2) end
    local pad = math.floor((w - #label) / 2)
    
    term.setBackgroundColor(bg)
    term.setTextColor(fg)
    term.setCursorPos(x, y)
    term.write(string.rep(" ", pad) .. label .. string.rep(" ", w - pad - #label))
end

function widget.label(x, y, text, fg, bg)
    local t = theme.get()
    fg = fg or t.window_fg
    bg = bg or t.window_bg
    term.setBackgroundColor(bg)
    term.setTextColor(fg)
    term.setCursorPos(x, y)
    term.write(text)
end

function widget.textbox(x, y, w, text, cursorPos, focused)
    local t = theme.get()
    local bg = t.input_bg
    local fg = t.input_fg
    local borderC = focused and t.accent or t.input_border
    
    term.setBackgroundColor(bg)
    term.setTextColor(fg)
    term.setCursorPos(x, y)
    
    local displayText = text or ""
    if #displayText > w then
        displayText = string.sub(displayText, #displayText - w + 1)
    end
    
    term.write(displayText .. string.rep(" ", w - #displayText))
    
    if focused then
        term.setCursorPos(x + (cursorPos or #text or 0), y)
        term.setCursorBlink(true)
    end
end

function widget.listbox(x, y, w, h, items, selectedIndex, scrollOffset)
    local t = theme.get()
    scrollOffset = scrollOffset or 0
    
    for i = 0, h - 1 do
        local itemIndex = i + 1 + scrollOffset
        local item = items[itemIndex]
        
        term.setCursorPos(x, y + i)
        
        if item then
            if itemIndex == selectedIndex then
                term.setBackgroundColor(t.accent)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(t.window_bg)
                term.setTextColor(t.window_fg)
            end
            
            local displayText = tostring(item)
            if #displayText > w then
                displayText = string.sub(displayText, 1, w)
            end
            term.write(displayText .. string.rep(" ", w - #displayText))
        else
            term.setBackgroundColor(t.window_bg)
            term.write(string.rep(" ", w))
        end
    end
end

function widget.menu(x, y, items, selectedIndex)
    local t = theme.get()
    local maxW = 0
    for _, item in ipairs(items) do
        if #item.text > maxW then maxW = #item.text end
    end
    local menuW = maxW + 4
    local menuH = #items + 2
    
    term.setBackgroundColor(t.menu_bg)
    term.setTextColor(t.menu_fg)
    for i = 0, menuH - 1 do
        term.setCursorPos(x, y + i)
        term.write(string.rep(" ", menuW))
    end
    
    for i = 0, menuH - 1 do
        term.setCursorPos(x, y + i)
        term.setBackgroundColor(t.border_color)
        term.write(" ")
        term.setCursorPos(x + menuW - 1, y + i)
        term.write(" ")
    end
    term.setCursorPos(x, y)
    term.setBackgroundColor(t.border_color)
    term.write(string.rep(" ", menuW))
    term.setCursorPos(x, y + menuH - 1)
    term.write(string.rep(" ", menuW))
    
    for i, item in ipairs(items) do
        local iy = y + i
        if i == selectedIndex then
            term.setBackgroundColor(t.menu_hover)
            term.setTextColor(colors.white)
        else
            term.setBackgroundColor(t.menu_bg)
            term.setTextColor(t.menu_fg)
        end
        term.setCursorPos(x + 2, iy)
        local text = item.text or ""
        term.write(text .. string.rep(" ", menuW - 4 - #text))
    end
    
    return menuW, menuH
end

function widget.checkbox(x, y, label, checked)
    local t = theme.get()
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(t.window_fg)
    term.setCursorPos(x, y)
    
    if checked then
        term.write("[X] " .. label)
    else
        term.write("[ ] " .. label)
    end
end

function widget.slider(x, y, w, min, max, value)
    local t = theme.get()
    local range = max - min
    local pos = math.floor((value - min) / range * (w - 1))
    
    term.setBackgroundColor(t.scrollbar_bg)
    term.setCursorPos(x, y)
    term.write(string.rep("-", w))
    
    term.setBackgroundColor(t.scrollbar_fg)
    term.setCursorPos(x + pos, y)
    term.write("#")
    
    return pos
end

function widget.separator(x, y, w)
    local t = theme.get()
    term.setBackgroundColor(t.border_color)
    term.setCursorPos(x, y)
    term.write(string.rep("-", w))
end

function widget.tabBar(x, y, tabs, activeTab)
    local t = theme.get()
    local tx = x
    
    for i, tab in ipairs(tabs) do
        local tabW = #tab + 2
        
        if i == activeTab then
            term.setBackgroundColor(t.window_bg)
            term.setTextColor(t.window_fg)
        else
            term.setBackgroundColor(t.button_bg)
            term.setTextColor(t.button_fg)
        end
        
        term.setCursorPos(tx, y)
        term.write(" " .. tab .. " ")
        tx = tx + tabW + 1
    end
    
    term.setBackgroundColor(t.window_bg)
    term.setCursorPos(tx, y)
    local sw = select(1, term.getSize())
    term.write(string.rep(" ", sw - tx + 1))
end

return widget
