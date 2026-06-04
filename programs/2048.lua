local theme = dofile("system/theme.lua")

local w, h = term.getSize()
local grid = {}
local score = 0
local gameOver = false
local won = false

local function initGame()
    grid = {}
    for y = 1, 4 do
        grid[y] = {}
        for x = 1, 4 do
            grid[y][x] = 0
        end
    end
    
    score = 0
    gameOver = false
    won = false
    
    spawnTile()
    spawnTile()
end

local function spawnTile()
    local empty = {}
    for y = 1, 4 do
        for x = 1, 4 do
            if grid[y][x] == 0 then
                table.insert(empty, {x = x, y = y})
            end
        end
    end
    
    if #empty > 0 then
        local pos = empty[math.random(1, #empty)]
        grid[pos.y][pos.x] = math.random(1, 10) == 1 and 4 or 2
    end
end

local function canMove()
    for y = 1, 4 do
        for x = 1, 4 do
            if grid[y][x] == 0 then return true end
            if x < 4 and grid[y][x] == grid[y][x + 1] then return true end
            if y < 4 and grid[y][x] == grid[y + 1][x] then return true end
        end
    end
    return false
end

local function checkWin()
    for y = 1, 4 do
        for x = 1, 4 do
            if grid[y][x] == 2048 then
                return true
            end
        end
    end
    return false
end

local function move(direction)
    local moved = false
    local merged = {}
    for y = 1, 4 do
        merged[y] = {}
        for x = 1, 4 do
            merged[y][x] = false
        end
    end
    
    local order = {}
    if direction == "left" then
        for y = 1, 4 do
            for x = 1, 4 do
                table.insert(order, {x = x, y = y})
            end
        end
    elseif direction == "right" then
        for y = 1, 4 do
            for x = 4, 1, -1 do
                table.insert(order, {x = x, y = y})
            end
        end
    elseif direction == "up" then
        for x = 1, 4 do
            for y = 1, 4 do
                table.insert(order, {x = x, y = y})
            end
        end
    elseif direction == "down" then
        for x = 1, 4 do
            for y = 4, 1, -1 do
                table.insert(order, {x = x, y = y})
            end
        end
    end
    
    for _, pos in ipairs(order) do
        local x, y = pos.x, pos.y
        if grid[y][x] ~= 0 then
            local nx, ny = x, y
            
            while true do
                local tx, ty = nx, ny
                if direction == "left" then tx = tx - 1
                elseif direction == "right" then tx = tx + 1
                elseif direction == "up" then ty = ty - 1
                elseif direction == "down" then ty = ty + 1
                end
                
                if tx < 1 or tx > 4 or ty < 1 or ty > 4 then break end
                
                if grid[ty][tx] == 0 then
                    grid[ty][tx] = grid[ny][nx]
                    grid[ny][nx] = 0
                    nx, ny = tx, ty
                    moved = true
                elseif grid[ty][tx] == grid[ny][nx] and not merged[ty][tx] and not merged[ny][nx] then
                    grid[ty][tx] = grid[ty][tx] * 2
                    score = score + grid[ty][tx]
                    grid[ny][nx] = 0
                    merged[ty][tx] = true
                    moved = true
                    break
                else
                    break
                end
            end
        end
    end
    
    return moved
end

local tileColors = {
    [2] = colors.white,
    [4] = colors.lightGray,
    [8] = colors.yellow,
    [16] = colors.orange,
    [32] = colors.red,
    [64] = colors.magenta,
    [128] = colors.purple,
    [256] = colors.blue,
    [512] = colors.cyan,
    [1024] = colors.green,
    [2048] = colors.lime,
}

local function draw()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    local cellW = math.floor((w - 10) / 4)
    local cellH = math.floor((h - 6) / 4)
    if cellW < 5 then cellW = 5 end
    if cellH < 3 then cellH = 3 end
    
    local startX = math.floor((w - cellW * 4) / 2)
    local startY = 2
    
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    term.write("2048 - Score: " .. score)
    
    for y = 1, 4 do
        for x = 1, 4 do
            local val = grid[y][x]
            local screenX = startX + (x - 1) * cellW
            local screenY = startY + (y - 1) * cellH
            
            term.setBackgroundColor(tileColors[val] or colors.gray)
            for dy = 0, cellH - 1 do
                term.setCursorPos(screenX, screenY + dy)
                term.write(string.rep(" ", cellW))
            end
            
            if val ~= 0 then
                term.setTextColor(colors.black)
                term.setCursorPos(screenX + math.floor((cellW - #tostring(val)) / 2), screenY + math.floor(cellH / 2))
                term.write(tostring(val))
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(2, h)
    if won then
        term.write("You Win! N for new game | Q to quit")
    elseif gameOver then
        term.write("Game Over! N for new game | Q to quit")
    else
        term.write("Arrow keys to move | Q to quit")
    end
end

initGame()
draw()

while true do
    local event = table.pack(os.pullEvent())
    
    if event[1] == "key" then
        local key = event[2]
        local dir = nil
        
        if key == keys.up then dir = "up"
        elseif key == keys.down then dir = "down"
        elseif key == keys.left then dir = "left"
        elseif key == keys.right then dir = "right"
        elseif key == keys.q or key == keys.escape then
            break
        elseif key == keys.n then
            initGame()
            draw()
        end
        
        if dir and not gameOver and not won then
            local moved = move(dir)
            if moved then
                spawnTile()
                if checkWin() then
                    won = true
                elseif not canMove() then
                    gameOver = true
                end
            elseif not canMove() then
                gameOver = true
            end
            draw()
        end
    end
end
