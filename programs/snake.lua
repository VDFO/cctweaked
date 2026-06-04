local theme = dofile("system/theme.lua")

local w, h = term.getSize()
local snake = {}
local food = {}
local direction = "right"
local nextDirection = "right"
local score = 0
local gameOver = false
local speed = 0.15

local function placeFood()
    while true do
        food = {
            x = math.random(2, w - 1),
            y = math.random(2, h - 2)
        }
        local onSnake = false
        for _, segment in ipairs(snake) do
            if segment.x == food.x and segment.y == food.y then
                onSnake = true
                break
            end
        end
        if not onSnake then break end
    end
end

local function initGame()
    snake = {
        {x = math.floor(w / 2), y = math.floor(h / 2)},
        {x = math.floor(w / 2) - 1, y = math.floor(h / 2)},
        {x = math.floor(w / 2) - 2, y = math.floor(h / 2)},
    }
    direction = "right"
    nextDirection = "right"
    score = 0
    gameOver = false
    speed = 0.15
    placeFood()
end

local function draw()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    term.setBackgroundColor(colors.green)
    for x = 1, w do
        term.setCursorPos(x, 1)
        term.write(" ")
        term.setCursorPos(x, h - 1)
        term.write(" ")
    end
    for y = 1, h - 1 do
        term.setCursorPos(1, y)
        term.write(" ")
        term.setCursorPos(w, y)
        term.write(" ")
    end
    
    term.setBackgroundColor(colors.red)
    term.setCursorPos(food.x, food.y)
    term.write(" ")
    
    for i, segment in ipairs(snake) do
        if i == 1 then
            term.setBackgroundColor(colors.lime)
        else
            term.setBackgroundColor(colors.green)
        end
        term.setCursorPos(segment.x, segment.y)
        term.write(" ")
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(2, h)
    term.write("Score: " .. score)
    term.setCursorPos(w - 12, h)
    if gameOver then
        term.write("Game Over!")
    else
        term.write("Arrow keys | Q")
    end
end

local function update()
    direction = nextDirection
    
    local head = {x = snake[1].x, y = snake[1].y}
    
    if direction == "up" then head.y = head.y - 1
    elseif direction == "down" then head.y = head.y + 1
    elseif direction == "left" then head.x = head.x - 1
    elseif direction == "right" then head.x = head.x + 1
    end
    
    if head.x <= 1 or head.x >= w or head.y <= 1 or head.y >= h - 1 then
        gameOver = true
        return
    end
    
    for i = 2, #snake do
        if snake[i].x == head.x and snake[i].y == head.y then
            gameOver = true
            return
        end
    end
    
    table.insert(snake, 1, head)
    
    if head.x == food.x and head.y == food.y then
        score = score + 10
        speed = math.max(0.05, speed - 0.005)
        placeFood()
    else
        table.remove(snake)
    end
end

initGame()
draw()

while true do
    local timerId = os.startTimer(speed)
    local event = table.pack(os.pullEvent())
    
    if event[1] == "timer" and event[2] == timerId then
        if not gameOver then
            update()
            draw()
        end
    elseif event[1] == "key" then
        local key = event[2]
        if key == keys.up and direction ~= "down" then
            nextDirection = "up"
        elseif key == keys.down and direction ~= "up" then
            nextDirection = "down"
        elseif key == keys.left and direction ~= "right" then
            nextDirection = "left"
        elseif key == keys.right and direction ~= "left" then
            nextDirection = "right"
        elseif key == keys.q or key == keys.escape then
            break
        elseif key == keys.n and gameOver then
            initGame()
            draw()
        end
    end
end
