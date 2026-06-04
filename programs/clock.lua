local theme = dofile("system/theme.lua")

local w, h = term.getSize()
local viewMonth = os.date("*t").month
local viewYear = os.date("*t").year
local alarms = {}

local monthNames = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
}

local dayNames = {"Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"}

local function getDaysInMonth(month, year)
    local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    if month == 2 then
        if year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) then
            return 29
        end
    end
    return days[month]
end

local function getFirstDayOfMonth(month, year)
    local t = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4}
    if month < 3 then year = year - 1 end
    return (year + math.floor(year/4) - math.floor(year/100) + math.floor(year/400) + t[month] + 1) % 7
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
    term.write("Clock & Calendar")
    
    local timeStr = textutils.formatTime(os.time(), true)
    local dateStr = os.date("%A, %B %d, %Y")
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(t.accent)
    term.setCursorPos(math.floor((w - #timeStr) / 2) + 1, 3)
    term.write(timeStr)
    
    term.setTextColor(t.window_fg)
    term.setCursorPos(math.floor((w - #dateStr) / 2) + 1, 4)
    term.write(dateStr)
    
    local calY = 6
    term.setTextColor(colors.gray)
    term.setCursorPos(1, calY)
    term.write(string.rep("-", w))
    
    calY = calY + 1
    local header = "< " .. monthNames[viewMonth] .. " " .. viewYear .. " >"
    term.setTextColor(t.window_fg)
    term.setCursorPos(math.floor((w - #header) / 2) + 1, calY)
    term.write(header)
    
    calY = calY + 2
    term.setTextColor(colors.gray)
    local dayHeader = ""
    for _, day in ipairs(dayNames) do
        dayHeader = dayHeader .. day .. " "
    end
    term.setCursorPos(math.floor((w - #dayHeader) / 2) + 1, calY)
    term.write(dayHeader)
    
    calY = calY + 1
    local firstDay = getFirstDayOfMonth(viewMonth, viewYear)
    local daysInMonth = getDaysInMonth(viewMonth, viewYear)
    local today = os.date("*t")
    
    local day = 1
    for week = 0, 5 do
        if day > daysInMonth then break end
        
        local lineX = math.floor((w - 21) / 2) + 1
        for dow = 0, 6 do
            if (week == 0 and dow < firstDay) or day > daysInMonth then
                term.setCursorPos(lineX + dow * 3, calY + week)
                term.write("   ")
            else
                term.setCursorPos(lineX + dow * 3, calY + week)
                
                if day == today.day and viewMonth == today.month and viewYear == today.year then
                    term.setBackgroundColor(t.accent)
                    term.setTextColor(colors.white)
                else
                    term.setBackgroundColor(t.window_bg)
                    term.setTextColor(t.window_fg)
                end
                
                term.write(string.format("%2d ", day))
                day = day + 1
            end
        end
    end
    
    term.setBackgroundColor(t.window_bg)
    term.setTextColor(colors.gray)
    term.setCursorPos(1, h - 1)
    term.write(string.rep("-", w))
    term.setCursorPos(2, h)
    term.write("< > change month | Q to quit")
end

draw()

local timerId = os.startTimer(1)

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "timer" and event[2] == timerId then
        draw()
        timerId = os.startTimer(1)
        
    elseif event[1] == "key" then
        if event[2] == keys.left then
            viewMonth = viewMonth - 1
            if viewMonth < 1 then
                viewMonth = 12
                viewYear = viewYear - 1
            end
            draw()
        elseif event[2] == keys.right then
            viewMonth = viewMonth + 1
            if viewMonth > 12 then
                viewMonth = 1
                viewYear = viewYear + 1
            end
            draw()
        elseif event[2] == keys.q then
            break
        end
        
    elseif event[1] == "mouse_click" then
        local x, y = event[3], event[4]
        local headerY = 8
        if y == headerY then
            local header = "< " .. monthNames[viewMonth] .. " " .. viewYear .. " >"
            local headerX = math.floor((w - #header) / 2) + 1
            if x < headerX + 2 then
                viewMonth = viewMonth - 1
                if viewMonth < 1 then viewMonth = 12; viewYear = viewYear - 1 end
                draw()
            elseif x > headerX + #header - 3 then
                viewMonth = viewMonth + 1
                if viewMonth > 12 then viewMonth = 1; viewYear = viewYear + 1 end
                draw()
            end
        end
    end
end
