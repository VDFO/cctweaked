local theme = dofile("system/theme.lua")

local w, h = term.getSize()
local board = {}
local revealed = {}
local flagged = {}
local gameOver = false
local won = false
local boardW = math.min(w - 4, 20)
local boardH = math.min(h - 5, 12)
local mineCount = math.floor(boardW * boardH * 0.15)
local startX = math.floor((w - boardW) / 2)
local startY = 2

local function initGame()
    board = {}
    revealed = {}
    flagged = {}
    gameOver = false
    won = false
    
    for y = 1, boardH do
        board[y] = {}
        revealed[y] = {}
        flagged[y] = {}
        for x = 1, boardW do
            board[y][x] = 0
            revealed[y][x] = false
            flagged[y][x] = false
        end
    end
    
    local minesPlaced = 0
    while minesPlaced < mineCount do
        local x = math.random(1, boardW)
        local y = math.random(1, boardH)
        if board[y][x] ~= -1 then
            board[y][x] = -1
            minesPlaced = minesPlaced + 1
            
            for dy = -1, 1 do
                for dx = -1, 1 do
                    local nx, ny = x + dx, y + dy
                    if nx >= 1 and nx <= boardW and ny >= 1 and ny <= boardH and board[ny][nx] ~= -1 then
                        board[ny][nx] = board[ny][nx] + 1
                    end
                end
            end
        end
    end
end

local function reveal(x, y)
    if x < 1 or x > boardW or y < 1 or y > boardH then return end
    if revealed[y][x] or flagged[y][x] then return end
    
    revealed[y][x] = true
    
    if board[y][x] == -1 then
        gameOver = true
        return
    end
    
    if board[y][x] == 0 then
        for dy = -1, 1 do
            for dx = -1, 1 do
                reveal(x + dx, y + dy)
            end
        end
    end
end

local function checkWin()
    for y = 1, boardH do
        for x = 1, boardW do
            if board[y][x] ~= -1 and not revealed[y][x] then
                return false
            end
        end
    end
    return true
end

local function draw()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    term.write("Minesweeper - Mines: " .. mineCount)
    
    for y = 1, boardH do
        for x = 1, boardW do
            term.setCursorPos(startX + x - 1, startY + y - 1)
            
            if revealed[y][x] then
                if board[y][x] == -1 then
                    term.setBackgroundColor(colors.red)
                    term.setTextColor(colors.white)
                    term.write("*")
                elseif board[y][x] == 0 then
                    term.setBackgroundColor(colors.lightGray)
                    term.write(" ")
                else
                    term.setBackgroundColor(colors.lightGray)
                    local numColors = {colors.blue, colors.green, colors.red, colors.purple, colors.brown, colors.cyan, colors.black, colors.gray}
                    term.setTextColor(numColors[board[y][x]] or colors.white)
                    term.write(tostring(board[y][x]))
                end
            elseif flagged[y][x] then
                term.setBackgroundColor(colors.yellow)
                term.setTextColor(colors.red)
                term.write("F")
            else
                term.setBackgroundColor(colors.gray)
                term.write(" ")
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(2, h)
    if gameOver then
        if won then
            term.write("You Win! Click to restart | Q to quit")
        else
            term.write("Game Over! Click to restart | Q to quit")
        end
    else
        term.write("Click to reveal | Right-click to flag | Q to quit")
    end
end

initGame()
draw()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "mouse_click" then
        local button, x, y = event[2], event[3], event[4]
        
        if gameOver or won then
            initGame()
            draw()
        else
            local boardX = x - startX + 1
            local boardY = y - startY + 1
            
            if boardX >= 1 and boardX <= boardW and boardY >= 1 and boardY <= boardH then
                if button == 1 then
                    reveal(boardX, boardY)
                    if checkWin() then
                        won = true
                        gameOver = true
                    end
                elseif button == 2 then
                    if not revealed[boardY][boardX] then
                        flagged[boardY][boardX] = not flagged[boardY][boardX]
                    end
                end
                draw()
            end
        end
        
    elseif event[1] == "key" then
        if event[2] == keys.q or event[2] == keys.escape then
            break
        end
    end
end
