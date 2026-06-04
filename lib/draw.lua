local draw = {}

local theme = dofile("system/theme.lua")

function draw.box(x, y, w, h, fg, bg)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setBackgroundColor(bg)
    term.setTextColor(fg)
    
    for i = 0, h - 1 do
        term.setCursorPos(x, y + i)
        term.write(string.rep(" ", w))
    end
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

function draw.border(x, y, w, h, color)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setBackgroundColor(color)
    term.setTextColor(color)
    
    for i = 0, h - 1 do
        term.setCursorPos(x, y + i)
        term.write(" ")
        term.setCursorPos(x + w - 1, y + i)
        term.write(" ")
    end
    
    term.setCursorPos(x, y)
    term.write(string.rep(" ", w))
    term.setCursorPos(x, y + h - 1)
    term.write(string.rep(" ", w))
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

function draw.shadow(x, y, w, h)
    local oldBg = term.getBackgroundColor()
    term.setBackgroundColor(colors.black)
    
    for i = 1, h do
        term.setCursorPos(x + w, y + i - 1)
        term.write(" ")
    end
    term.setCursorPos(x + 1, y + h)
    term.write(string.rep(" ", w))
    
    term.setBackgroundColor(oldBg)
end

function draw.text(x, y, text, fg, bg)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setBackgroundColor(bg)
    term.setTextColor(fg)
    term.setCursorPos(x, y)
    term.write(text)
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

function draw.centeredText(y, text, fg, bg, screenWidth)
    local x = math.floor((screenWidth - #text) / 2) + 1
    draw.text(x, y, text, fg, bg)
    return x
end

function draw.icon(x, y, iconName)
    local iconPath = "assets/icons/" .. iconName .. ".nfp"
    if fs.exists(iconPath) then
        local image = paintutils.loadImage(iconPath)
        if image then
            paintutils.drawImage(image, x, y)
            return true
        end
    end
    return false
end

function draw.progressBar(x, y, w, percent, fg, bg)
    local filled = math.floor(w * percent)
    local empty = w - filled
    
    local oldBg = term.getBackgroundColor()
    term.setCursorPos(x, y)
    
    term.setBackgroundColor(fg)
    term.write(string.rep(" ", filled))
    
    term.setBackgroundColor(bg)
    term.write(string.rep(" ", empty))
    
    term.setBackgroundColor(oldBg)
end

function draw.scrollbar(x, y, h, position, total)
    if total <= 0 then return end
    
    local oldBg = term.getBackgroundColor()
    local t = theme.get()
    
    term.setBackgroundColor(t.scrollbar_bg)
    for i = 0, h - 1 do
        term.setCursorPos(x, y + i)
        term.write(" ")
    end
    
    local thumbSize = math.max(1, math.floor(h * (h / total)))
    local thumbPos = math.floor((h - thumbSize) * (position / total))
    
    term.setBackgroundColor(t.scrollbar_fg)
    for i = 0, thumbSize - 1 do
        term.setCursorPos(x, y + thumbPos + i)
        term.write(" ")
    end
    
    term.setBackgroundColor(oldBg)
end

function draw.titleBar(x, y, w, title, active)
    local t = theme.get()
    local bg = active and t.titlebar_bg or t.titlebar_inactive_bg
    local fg = active and t.titlebar_fg or t.titlebar_inactive_fg
    
    draw.box(x, y, w, 1, fg, bg)
    
    local maxTitleLen = w - 6
    if #title > maxTitleLen then
        title = string.sub(title, 1, maxTitleLen - 3) .. "..."
    end
    
    local titleX = x + 2
    draw.text(titleX, y, title, fg, bg)
    
    draw.text(x + w - 4, y, "[_]", fg, bg)
    draw.text(x + w - 1, y, "X", fg, bg)
end

function draw.button(x, y, text, fg, bg, hover)
    local displayText = "[" .. text .. "]"
    draw.text(x, y, displayText, fg, bg)
    return x, y, #displayText, 1
end

return draw
