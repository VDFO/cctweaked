local theme = dofile("system/theme.lua")

local w, h = term.getSize()
local board = {}
local currentPiece = nil
local currentX = 0
local currentY = 0
local score = 0
local gameOver = false
local linesCleared = 0

local pieces = {
    { {1,1,1,1} },
    { {1,1}, {1,1} },
    { {0,1,0}, {1,1,1} },
    { {1,0,0}, {1,1,1} },
    { {0,0,1}, {1,1,1} },
    { {0,1,1}, {1,1,0} },
    { {1,1,0}, {0,1,1} },
}

local pieceColors = {
    colors.cyan,
    colors.yellow,
    colors.purple,
    colors.orange,
    colors.blue,
    colors.green,
    colors.red,
}

local function newPiece()
    local pieceType = math.random(1, #pieces)
    currentPiece = {}
    for y = 1, #pieces[pieceType] do
        currentPiece[y] = {}
        for x = 1, #pieces[pieceType][y] do
            currentPiece[y][x] = pieces[pieceType][y][x]
        end
    end
    currentX = math.floor((10 - #currentPiece[1]) / 2)
    currentY = 1
end

local function initGame()
    board = {}
    for y = 1, 20 do
        board[y] = {}
        for x = 1, 10 do
            board[y][x] = 0
        end
    end
    score = 0
    linesCleared = 0
    gameOver = false
    newPiece()
end

local function canPlace(piece, px, py)
    for y = 1, #piece do
        for x = 1, #piece[y] do
            if piece[y][x] == 1 then
                local bx = px + x - 1
                local by = py + y - 1
                if bx < 1 or bx > 10 or by > 20 then return false end
                if by >= 1 and board[by][bx] ~= 0 then return false end
            end
        end
    end
    return true
end

local function placePiece()
    for y = 1, #currentPiece do
        for x = 1, #currentPiece[y] do
            if currentPiece[y][x] == 1 then
                local by = currentY + y - 1
                if by >= 1 then
                    board[by][currentX + x - 1] = 1
                end
            end
        end
    end
    
    local cleared = 0
    for y = 20, 1, -1 do
        local full = true
        for x = 1, 10 do
            if board[y][x] == 0 then
                full = false
                break
            end
        end
        if full then
            cleared = cleared + 1
            for moveY = y, 2, -1 do
                for x = 1, 10 do
                    board[moveY][x] = board[moveY - 1][x]
                end
            end
            for x = 1, 10 do
                board[1][x] = 0
            end
            y = y + 1
        end
    end
    
    if cleared > 0 then
        linesCleared = linesCleared + cleared
        score = score + cleared * 100 * cleared
    end
    
    newPiece()
    if not canPlace(currentPiece, currentX, currentY) then
        gameOver = true
    end
end

local function rotate()
    local rotated = {}
    for x = 1, #currentPiece[1] do
        rotated[x] = {}
        for y = #currentPiece, 1, -1 do
            rotated[x][#currentPiece - y + 1] = currentPiece[y][x]
        end
    end
    
    if canPlace(rotated, currentX, currentY) then
        currentPiece = rotated
    end
end

local function draw()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    local startX = math.floor((w - 12) / 2)
    local startY = 2
    
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    term.write("Tetris - Score: " .. score .. " Lines: " .. linesCleared)
    
    for y = 1, 20 do
        term.setCursorPos(startX, startY + y - 1)
        term.setBackgroundColor(colors.gray)
        term.write(" ")
        
        for x = 1, 10 do
            term.setCursorPos(startX + x, startY + y - 1)
            if board[y][x] ~= 0 then
                term.setBackgroundColor(colors.lightBlue)
            else
                term.setBackgroundColor(colors.black)
            end
            term.write(" ")
        end
        
        term.setCursorPos(startX + 11, startY + y - 1)
        term.setBackgroundColor(colors.gray)
        term.write(" ")
    end
    
    if currentPiece then
        for y = 1, #currentPiece do
            for x = 1, #currentPiece[y] do
                if currentPiece[y][x] == 1 then
                    local screenX = startX + currentX + x - 1
                    local screenY = startY + currentY + y - 2
                    if screenY >= startY and screenY < startY + 20 then
                        term.setCursorPos(screenX, screenY)
                        term.setBackgroundColor(colors.lime)
                        term.write(" ")
                    end
                end
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(2, h)
    if gameOver then
        term.write("Game Over! N for new game | Q to quit")
    else
        term.write("Arrows: move | Up: rotate | Down: drop | Q: quit")
    end
end

initGame()
draw()

local dropTimer = os.startTimer(0.5)

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "timer" and event[2] == dropTimer then
        if not gameOver then
            if canPlace(currentPiece, currentX, currentY + 1) then
                currentY = currentY + 1
            else
                placePiece()
            end
            draw()
        end
        dropTimer = os.startTimer(math.max(0.1, 0.5 - linesCleared * 0.02))
    elseif event[1] == "key" then
        local key = event[2]
        
        if key == keys.q or key == keys.escape then
            break
        elseif key == keys.n and gameOver then
            initGame()
            draw()
        elseif not gameOver then
            if key == keys.left then
                if canPlace(currentPiece, currentX - 1, currentY) then
                    currentX = currentX - 1
                    draw()
                end
            elseif key == keys.right then
                if canPlace(currentPiece, currentX + 1, currentY) then
                    currentX = currentX + 1
                    draw()
                end
            elseif key == keys.down then
                if canPlace(currentPiece, currentX, currentY + 1) then
                    currentY = currentY + 1
                    draw()
                end
            elseif key == keys.up then
                rotate()
                draw()
            end
        end
    end
end
