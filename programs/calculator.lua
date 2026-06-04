local theme = dofile("system/theme.lua")

local w, h = term.getSize()
local display = "0"
local memory = 0
local history = {}
local expression = ""
local lastAnswer = 0

local buttons = {
    {"C",  "<-", "%",  "/"},
    {"7",  "8",  "9",  "*"},
    {"4",  "5",  "6",  "-"},
    {"1",  "2",  "3",  "+"},
    {"M+", "M-", "MR", "="},
    {"(",  "0",  ")",  "."},
}

local function draw()
    local t = theme.get()
    term.setBackgroundColor(t.window_bg)
    term.clear()
    
    term.setBackgroundColor(t.titlebar_bg)
    term.setTextColor(t.titlebar_fg)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    term.write("Calculator")
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.lime)
    term.setCursorPos(1, 2)
    term.write(string.rep(" ", w))
    term.setCursorPos(1, 3)
    term.write(string.rep(" ", w))
    
    if #expression > 0 then
        term.setCursorPos(2, 2)
        local exprDisplay = expression
        if #exprDisplay > w - 2 then
            exprDisplay = string.sub(exprDisplay, #exprDisplay - w + 3)
        end
        term.write(exprDisplay)
    end
    
    local dispText = display
    if #dispText > w - 2 then
        dispText = string.sub(dispText, #dispText - w + 3)
    end
    term.setCursorPos(w - #dispText, 3)
    term.write(dispText)
    
    local btnW = math.floor((w - 2) / 4)
    local btnH = 2
    local startY = 5
    
    for row, rowBtns in ipairs(buttons) do
        for col, btn in ipairs(rowBtns) do
            local bx = 1 + (col - 1) * (btnW + 1)
            local by = startY + (row - 1) * (btnH + 1)
            
            local bgColor = t.button_bg
            local fgColor = t.button_fg
            
            if btn == "=" then
                bgColor = t.accent
                fgColor = colors.white
            elseif btn == "C" or btn == "<-" then
                bgColor = colors.red
                fgColor = colors.white
            elseif btn:match("[%d%.]") then
                bgColor = t.window_bg
                fgColor = t.window_fg
            end
            
            term.setBackgroundColor(bgColor)
            term.setTextColor(fgColor)
            
            for i = 0, btnH - 1 do
                term.setCursorPos(bx, by + i)
                local pad = math.floor((btnW - #btn) / 2)
                term.write(string.rep(" ", pad) .. btn .. string.rep(" ", btnW - pad - #btn))
            end
        end
    end
    
    if #history > 0 then
        term.setBackgroundColor(t.window_bg)
        term.setTextColor(colors.gray)
        term.setCursorPos(1, h - 1)
        term.write(string.rep("-", w))
        term.setCursorPos(2, h)
        term.write("History: " .. history[#history])
    end
end

local function evaluate(expr)
    local safeExpr = expr:gsub("[^%d%.%+%-%*%/%%%(%)%.]", "")
    local func, err = load("return " .. safeExpr)
    if func then
        local ok, result = pcall(func)
        if ok and result then
            return tostring(result)
        end
    end
    return "Error"
end

local function handleButton(btn)
    if btn == "C" then
        display = "0"
        expression = ""
    elseif btn == "<-" then
        if #display > 1 then
            display = string.sub(display, 1, #display - 1)
        else
            display = "0"
        end
    elseif btn == "=" then
        local fullExpr = expression .. display
        local result = evaluate(fullExpr)
        table.insert(history, fullExpr .. " = " .. result)
        lastAnswer = tonumber(result) or 0
        display = result
        expression = ""
    elseif btn == "M+" then
        memory = memory + (tonumber(display) or 0)
    elseif btn == "M-" then
        memory = memory - (tonumber(display) or 0)
    elseif btn == "MR" then
        display = tostring(memory)
    elseif btn == "+" or btn == "-" or btn == "*" or btn == "/" or btn == "%" then
        expression = expression .. display .. " " .. btn .. " "
        display = "0"
    elseif btn == "(" or btn == ")" then
        expression = expression .. btn
    elseif btn == "." then
        if not display:find("%.") then
            display = display .. "."
        end
    else
        if display == "0" then
            display = btn
        else
            display = display .. btn
        end
    end
end

draw()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "mouse_click" then
        local x, y = event[3], event[4]
        
        local btnW = math.floor((w - 2) / 4)
        local btnH = 2
        local startY = 5
        
        for row, rowBtns in ipairs(buttons) do
            for col, btn in ipairs(rowBtns) do
                local bx = 1 + (col - 1) * (btnW + 1)
                local by = startY + (row - 1) * (btnH + 1)
                
                if x >= bx and x < bx + btnW and y >= by and y < by + btnH then
                    handleButton(btn)
                    draw()
                end
            end
        end
        
    elseif event[1] == "char" then
        local ch = event[2]
        if ch:match("%d") or ch == "." then
            handleButton(ch)
            draw()
        elseif ch == "+" or ch == "-" or ch == "*" or ch == "/" then
            handleButton(ch)
            draw()
        elseif ch == "=" or ch == "\n" then
            handleButton("=")
            draw()
        end
        
    elseif event[1] == "key" then
        if event[2] == keys.enter then
            handleButton("=")
            draw()
        elseif event[2] == keys.backspace then
            handleButton("<-")
            draw()
        elseif event[2] == keys.escape then
            break
        end
    end
end
