local theme = dofile("system/theme.lua")

local w, h = term.getSize()
local board = {}
local currentPlayer = "X"
local gameOver = false
local winner = nil

local function initGame()
    board = {}
    for y = 1, 3 do
        board[y] = {}
        for x = 1, 3 do
            board[y][x] = ""
        end
    end
    currentPlayer = "X"
    gameOver = false
    winner = nil
end

local function checkWin()
    for y = 1, 3 do
        if board[y][1] ~= "" and board[y][1] == board[y][2] and board[y][2] == board[y][3] then
            return board[y][1]
        end
    end
    
    for x = 1, 3 do
        if board[1][x] ~= "" and board[1][x] == board[2][x] and board[2][x] == board[3][x] then
            return board[1][x]
        end
    end
    
    if board[1][1] ~= "" and board[1][1] == board[2][2] and board[2][2] == board[3][3] then
        return board[1][1]
    end
    
    if board[1][3] ~= "" and board[1][3] == board[2][2] and board[2][2] == board[3][1] then
        return board[1][3]
    end
    
    local full = true
    for y = 1, 3 do
        for x = 1, 3 do
            if board[y][x] == "" then
                full = false
                break
            end
        end
    end
    
    if full then return "draw" end
    
    return nil
end

local function draw()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    local cellW = 7
    local cellH = 3
    local startX = math.floor((w - cellW * 3) / 2)
    local startY = 3
    
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    if gameOver then
        if winner == "draw" then
            term.write("Tic-Tac-Toe - Draw!")
        else
            term.write("Tic-Tac-Toe - " .. winner .. " wins!")
        end
    else
        term.write("Tic-Tac-Toe - Turn: " .. currentPlayer)
    end
    
    for y = 1, 3 do
        for x = 1, 3 do
            local screenX = startX + (x - 1) * cellW
            local screenY = startY + (y - 1) * cellH
            
            term.setBackgroundColor(colors.gray)
            for dy = 0, cellH - 1 do
                term.setCursorPos(screenX, screenY + dy)
                term.write(string.rep(" ", cellW))
            end
            
            if board[y][x] ~= "" then
                if board[y][x] == "X" then
                    term.setBackgroundColor(colors.red)
                else
                    term.setBackgroundColor(colors.cyan)
                end
                term.setTextColor(colors.white)
                term.setCursorPos(screenX + math.floor(cellW / 2), screenY + math.floor(cellH / 2))
                term.write(board[y][x])
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(2, h)
    if gameOver then
        term.write("Click to restart | Q to quit")
    else
        term.write("Click empty cell to place | Q to quit")
    end
end

initGame()
draw()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "mouse_click" then
        local x, y = event[3], event[4]
        
        if gameOver then
            initGame()
            draw()
        else
            local cellW = 7
            local cellH = 3
            local startX = math.floor((w - cellW * 3) / 2)
            local startY = 3
            
            local boardX = math.floor((x - startX) / cellW) + 1
            local boardY = math.floor((y - startY) / cellH) + 1
            
            if boardX >= 1 and boardX <= 3 and boardY >= 1 and boardY <= 3 then
                if board[boardY][boardX] == "" then
                    board[boardY][boardX] = currentPlayer
                    
                    local result = checkWin()
                    if result then
                        gameOver = true
                        winner = result
                    else
                        currentPlayer = (currentPlayer == "X") and "O" or "X"
                    end
                    
                    draw()
                end
            end
        end
        
    elseif event[1] == "key" then
        if event[2] == keys.q or event[2] == keys.escape then
            break
        end
    end
end
