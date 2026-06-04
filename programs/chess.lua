local theme = dofile("system/theme.lua")
local network = dofile("lib/network.lua")

local w, h = term.getSize()

local board = {}
local selectedSquare = nil
local validMoves = {}
local currentTurn = "white"
local moveHistory = {}
local capturedWhite = {}
local capturedBlack = {}
local gameOver = false
local gameMode = "local"
local lastMove = nil
local enPassantTarget = nil
local showAnalysis = false

local pieceSymbols = {
    pawn = {white = "P", black = "p"},
    rook = {white = "R", black = "r"},
    knight = {white = "N", black = "n"},
    bishop = {white = "B", black = "b"},
    queen = {white = "Q", black = "q"},
    king = {white = "K", black = "k"},
}

local pieceValues = {
    pawn = 1,
    knight = 3,
    bishop = 3,
    rook = 5,
    queen = 9,
    king = 0,
}

local function initBoard()
    board = {}
    for y = 1, 8 do
        board[y] = {}
        for x = 1, 8 do
            board[y][x] = nil
        end
    end
    
    local backRow = {"rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"}
    for x = 1, 8 do
        board[1][x] = {type = backRow[x], color = "black"}
        board[2][x] = {type = "pawn", color = "black"}
        board[7][x] = {type = "pawn", color = "white"}
        board[8][x] = {type = backRow[x], color = "white"}
    end
    
    lastMove = nil
    enPassantTarget = nil
end

local function isInBounds(x, y)
    return x >= 1 and x <= 8 and y >= 1 and y <= 8
end

local function getPiece(x, y)
    if not isInBounds(x, y) then return nil end
    return board[y][x]
end

local function isSquareAttacked(x, y, byColor)
    for dy = 1, 8 do
        for dx = 1, 8 do
            local piece = board[dy][dx]
            if piece and piece.color == byColor then
                local moves = getRawMoves(dx, dy, true)
                for _, move in ipairs(moves) do
                    if move.x == x and move.y == y then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function getRawMoves(x, y, attackOnly)
    local piece = board[y][x]
    if not piece then return {} end
    
    local moves = {}
    local color = piece.color
    local enemy = (color == "white") and "black" or "white"
    
    if piece.type == "pawn" then
        local dir = (color == "white") and -1 or 1
        local startRow = (color == "white") and 7 or 2
        
        if not attackOnly then
            if isInBounds(x, y + dir) and not board[y + dir][x] then
                table.insert(moves, {x = x, y = y + dir})
                if y == startRow and not board[y + 2 * dir][x] then
                    table.insert(moves, {x = x, y = y + 2 * dir})
                end
            end
        end
        
        for _, dx in ipairs({-1, 1}) do
            if isInBounds(x + dx, y + dir) then
                local target = board[y + dir][x + dx]
                if target and target.color == enemy then
                    table.insert(moves, {x = x + dx, y = y + dir})
                elseif attackOnly then
                    table.insert(moves, {x = x + dx, y = y + dir})
                elseif enPassantTarget and enPassantTarget.x == x + dx and enPassantTarget.y == y + dir then
                    table.insert(moves, {x = x + dx, y = y + dir, enPassant = true})
                end
            end
        end
        
    elseif piece.type == "knight" then
        local knightMoves = {{-2,-1},{-2,1},{-1,-2},{-1,2},{1,-2},{1,2},{2,-1},{2,1}}
        for _, move in ipairs(knightMoves) do
            local nx, ny = x + move[1], y + move[2]
            if isInBounds(nx, ny) then
                local target = board[ny][nx]
                if not target or target.color == enemy then
                    table.insert(moves, {x = nx, y = ny})
                end
            end
        end
        
    elseif piece.type == "bishop" or piece.type == "rook" or piece.type == "queen" then
        local directions = {}
        if piece.type == "bishop" or piece.type == "queen" then
            table.insert(directions, {-1, -1})
            table.insert(directions, {-1, 1})
            table.insert(directions, {1, -1})
            table.insert(directions, {1, 1})
        end
        if piece.type == "rook" or piece.type == "queen" then
            table.insert(directions, {-1, 0})
            table.insert(directions, {1, 0})
            table.insert(directions, {0, -1})
            table.insert(directions, {0, 1})
        end
        
        for _, dir in ipairs(directions) do
            local nx, ny = x + dir[1], y + dir[2]
            while isInBounds(nx, ny) do
                local target = board[ny][nx]
                if not target then
                    table.insert(moves, {x = nx, y = ny})
                else
                    if target.color == enemy then
                        table.insert(moves, {x = nx, y = ny})
                    end
                    break
                end
                nx = nx + dir[1]
                ny = ny + dir[2]
            end
        end
        
    elseif piece.type == "king" then
        for dy = -1, 1 do
            for dx = -1, 1 do
                if dx ~= 0 or dy ~= 0 then
                    local nx, ny = x + dx, y + dy
                    if isInBounds(nx, ny) then
                        local target = board[ny][nx]
                        if not target or target.color == enemy then
                            table.insert(moves, {x = nx, y = ny})
                        end
                    end
                end
            end
        end
    end
    
    return moves
end

local function findKing(color)
    for y = 1, 8 do
        for x = 1, 8 do
            local piece = board[y][x]
            if piece and piece.type == "king" and piece.color == color then
                return x, y
            end
        end
    end
    return nil, nil
end

local function isInCheck(color)
    local kx, ky = findKing(color)
    if not kx then return false end
    local enemy = (color == "white") and "black" or "white"
    return isSquareAttacked(kx, ky, enemy)
end

local function getValidMoves(x, y)
    local piece = board[y][x]
    if not piece then return {} end
    
    local rawMoves = getRawMoves(x, y, false)
    local validMoves = {}
    
    for _, move in ipairs(rawMoves) do
        local captured = board[move.y][move.x]
        local capturedEnPassant = nil
        
        if move.enPassant then
            local capturedY = (piece.color == "white") and move.y + 1 or move.y - 1
            capturedEnPassant = board[capturedY][move.x]
            board[capturedY][move.x] = nil
        end
        
        board[move.y][move.x] = piece
        board[y][x] = nil
        
        if not isInCheck(piece.color) then
            table.insert(validMoves, move)
        end
        
        board[y][x] = piece
        board[move.y][move.x] = captured
        
        if move.enPassant then
            local capturedY = (piece.color == "white") and move.y + 1 or move.y - 1
            board[capturedY][move.x] = capturedEnPassant
        end
    end
    
    return validMoves
end

local function hasAnyValidMoves(color)
    for y = 1, 8 do
        for x = 1, 8 do
            local piece = board[y][x]
            if piece and piece.color == color then
                local moves = getValidMoves(x, y)
                if #moves > 0 then
                    return true
                end
            end
        end
    end
    return false
end

local function makeMove(fromX, fromY, toX, toY)
    local piece = board[fromY][fromX]
    local captured = board[toY][toX]
    
    enPassantTarget = nil
    
    if piece.type == "pawn" and math.abs(toY - fromY) == 2 then
        enPassantTarget = {x = fromX, y = (fromY + toY) / 2}
    end
    
    if captured then
        if captured.color == "white" then
            table.insert(capturedWhite, captured)
        else
            table.insert(capturedBlack, captured)
        end
    end
    
    for _, move in ipairs(validMoves) do
        if move.x == toX and move.y == toY and move.enPassant then
            local capturedY = (piece.color == "white") and toY + 1 or toY - 1
            local capturedPawn = board[capturedY][toX]
            if capturedPawn then
                if capturedPawn.color == "white" then
                    table.insert(capturedWhite, capturedPawn)
                else
                    table.insert(capturedBlack, capturedPawn)
                end
                board[capturedY][toX] = nil
            end
            break
        end
    end
    
    board[toY][toX] = piece
    board[fromY][fromX] = nil
    
    if piece.type == "pawn" and (toY == 1 or toY == 8) then
        board[toY][toX] = {type = "queen", color = piece.color}
    end
    
    lastMove = {fromX = fromX, fromY = fromY, toX = toX, toY = toY}
    
    local moveStr = string.format("%s%s to %s%s",
        string.char(96 + fromX), tostring(9 - fromY),
        string.char(96 + toX), tostring(9 - toY))
    table.insert(moveHistory, moveStr)
    
    currentTurn = (currentTurn == "white") and "black" or "white"
    
    if isInCheck(currentTurn) then
        if not hasAnyValidMoves(currentTurn) then
            gameOver = true
            return "checkmate"
        end
        return "check"
    elseif not hasAnyValidMoves(currentTurn) then
        gameOver = true
        return "stalemate"
    end
    
    return "ok"
end

local function evaluatePosition()
    local score = 0
    
    for y = 1, 8 do
        for x = 1, 8 do
            local piece = board[y][x]
            if piece then
                local value = pieceValues[piece.type] or 0
                if piece.color == "white" then
                    score = score + value
                else
                    score = score - value
                end
            end
        end
    end
    
    return score
end

local function drawAnalysisBar(eval)
    local barX = 2
    local barY = h - 2
    local barW = w - 4
    local barH = 1
    
    local maxEval = 20
    local clampedEval = math.max(-maxEval, math.min(maxEval, eval))
    local whitePercent = (clampedEval + maxEval) / (2 * maxEval)
    local whiteWidth = math.floor(barW * whitePercent)
    
    term.setBackgroundColor(colors.white)
    term.setCursorPos(barX, barY)
    term.write(string.rep(" ", whiteWidth))
    
    term.setBackgroundColor(colors.black)
    term.write(string.rep(" ", barW - whiteWidth))
    
    term.setCursorPos(barX, barY + 1)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    
    local evalText = ""
    if eval > 0 then
        evalText = string.format("+%.1f", eval)
    elseif eval < 0 then
        evalText = string.format("%.1f", eval)
    else
        evalText = "0.0"
    end
    
    term.write(" Evaluation: " .. evalText .. " ")
end

local function drawBoard()
    local t = theme.get()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    local boardSize = math.min(w - 20, h - 4)
    local cellW = math.floor(boardSize / 8)
    local cellH = math.floor((boardSize * 0.6) / 8)
    
    if cellW < 3 then cellW = 3 end
    if cellH < 2 then cellH = 2 end
    
    local boardW = cellW * 8
    local boardH = cellH * 8
    local boardX = math.max(2, math.floor((w - boardW - 15) / 2))
    local boardY = 2
    
    for y = 1, 8 do
        for x = 1, 8 do
            local screenX = boardX + (x - 1) * cellW
            local screenY = boardY + (y - 1) * cellH
            
            local isLight = (x + y) % 2 == 0
            local bgColor = isLight and colors.lightGray or colors.brown
            
            if selectedSquare and selectedSquare.x == x and selectedSquare.y == y then
                bgColor = colors.yellow
            end
            
            local isValidMove = false
            for _, move in ipairs(validMoves) do
                if move.x == x and move.y == y then
                    isValidMove = true
                    break
                end
            end
            if isValidMove then
                bgColor = colors.lime
            end
            
            term.setBackgroundColor(bgColor)
            for dy = 0, cellH - 1 do
                term.setCursorPos(screenX, screenY + dy)
                term.write(string.rep(" ", cellW))
            end
            
            local piece = board[y][x]
            if piece then
                local symbol = pieceSymbols[piece.type][piece.color]
                local pieceColor = (piece.color == "white") and colors.white or colors.black
                local pieceBg = (piece.color == "white") and colors.black or colors.white
                
                term.setTextColor(pieceColor)
                term.setBackgroundColor(pieceBg)
                term.setCursorPos(screenX + math.floor(cellW / 2), screenY + math.floor(cellH / 2))
                term.write(symbol)
            end
            
            if isValidMove and not piece then
                term.setTextColor(colors.white)
                term.setBackgroundColor(bgColor)
                term.setCursorPos(screenX + math.floor(cellW / 2), screenY + math.floor(cellH / 2))
                term.write("o")
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    for y = 1, 8 do
        term.setCursorPos(boardX - 1, boardY + (y - 1) * cellH + math.floor(cellH / 2))
        term.write(tostring(9 - y))
    end
    
    for x = 1, 8 do
        term.setCursorPos(boardX + (x - 1) * cellW + math.floor(cellW / 2), boardY + boardH)
        term.write(string.char(96 + x))
    end
    
    local infoX = boardX + boardW + 2
    term.setTextColor(colors.white)
    term.setCursorPos(infoX, 2)
    term.write("Turn: " .. currentTurn)
    
    term.setCursorPos(infoX, 4)
    term.write("Captured:")
    
    term.setCursorPos(infoX, 5)
    term.setTextColor(colors.white)
    term.write("W: ")
    for _, piece in ipairs(capturedWhite) do
        term.write(pieceSymbols[piece.type].white)
    end
    
    term.setCursorPos(infoX, 6)
    term.setTextColor(colors.black)
    term.setBackgroundColor(colors.white)
    term.write("B: ")
    for _, piece in ipairs(capturedBlack) do
        term.write(pieceSymbols[piece.type].black)
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(infoX, 8)
    term.write("Moves:")
    
    local moveY = 9
    local startMove = math.max(1, #moveHistory - 10)
    for i = startMove, #moveHistory do
        term.setCursorPos(infoX, moveY)
        term.write(i .. ". " .. moveHistory[i])
        moveY = moveY + 1
        if moveY > h - 4 then break end
    end
    
    if showAnalysis then
        local eval = evaluatePosition()
        drawAnalysisBar(eval)
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    term.setCursorPos(2, h)
    if gameOver then
        term.write("Game Over! Press A for analysis, Q to quit, N for new game")
    else
        term.write("Click to select/move | Q to quit | N for new game")
    end
end

local function showGameOver(result)
    local t = theme.get()
    local msg = ""
    
    if result == "checkmate" then
        local winner = (currentTurn == "white") and "Black" or "White"
        msg = "Checkmate! " .. winner .. " wins!"
    elseif result == "stalemate" then
        msg = "Stalemate! Draw!"
    end
    
    local msgW = #msg + 4
    local msgH = 5
    local msgX = math.floor((w - msgW) / 2)
    local msgY = math.floor((h - msgH) / 2)
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    for i = 0, msgH - 1 do
        term.setCursorPos(msgX, msgY + i)
        term.write(string.rep(" ", msgW))
    end
    
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(msgX, msgY)
    term.write(string.rep(" ", msgW))
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(msgX + 2, msgY + 2)
    term.write(msg)
end

initBoard()
drawBoard()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "mouse_click" then
        if gameOver then
            break
        end
        
        local x, y = event[3], event[4]
        
        local boardSize = math.min(w - 20, h - 4)
        local cellW = math.floor(boardSize / 8)
        local cellH = math.floor((boardSize * 0.6) / 8)
        
        if cellW < 3 then cellW = 3 end
        if cellH < 2 then cellH = 2 end
        
        local boardW = cellW * 8
        local boardH = cellH * 8
        local boardX = math.max(2, math.floor((w - boardW - 15) / 2))
        local boardY = 2
        
        if x >= boardX and x < boardX + boardW and y >= boardY and y < boardY + boardH then
            local squareX = math.floor((x - boardX) / cellW) + 1
            local squareY = math.floor((y - boardY) / cellH) + 1
            
            if isInBounds(squareX, squareY) then
                if selectedSquare then
                    local isValidMove = false
                    for _, move in ipairs(validMoves) do
                        if move.x == squareX and move.y == squareY then
                            isValidMove = true
                            break
                        end
                    end
                    
                    if isValidMove then
                        local result = makeMove(selectedSquare.x, selectedSquare.y, squareX, squareY)
                        selectedSquare = nil
                        validMoves = {}
                        drawBoard()
                        
                        if result == "checkmate" or result == "stalemate" then
                            showGameOver(result)
                        end
                    else
                        local piece = board[squareY][squareX]
                        if piece and piece.color == currentTurn then
                            selectedSquare = {x = squareX, y = squareY}
                            validMoves = getValidMoves(squareX, squareY)
                            drawBoard()
                        else
                            selectedSquare = nil
                            validMoves = {}
                            drawBoard()
                        end
                    end
                else
                    local piece = board[squareY][squareX]
                    if piece and piece.color == currentTurn then
                        selectedSquare = {x = squareX, y = squareY}
                        validMoves = getValidMoves(squareX, squareY)
                        drawBoard()
                    end
                end
            end
        end
        
    elseif event[1] == "key" then
        if event[2] == keys.q then
            break
        elseif event[2] == keys.n then
            initBoard()
            selectedSquare = nil
            validMoves = {}
            currentTurn = "white"
            moveHistory = {}
            capturedWhite = {}
            capturedBlack = {}
            gameOver = false
            showAnalysis = false
            drawBoard()
        elseif event[2] == keys.a and gameOver then
            showAnalysis = not showAnalysis
            drawBoard()
        end
    end
end
