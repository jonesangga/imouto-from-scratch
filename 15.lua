local game = require("game")
local fsm  = require("fsm")

local _15 = {
    name = "15",
}

local WIDTH = 480 - 2 * game.screen_padding
local GAP = 4
local GRID = 4
local TILE_SIZE = (WIDTH - (GRID - 1) * GAP) / GRID

local tiles = {}                -- tile numbers; 0 for empty
local er, ec = GRID, GRID
local font = game.font_mono
local moves = 0
local is_shuffling = false
local solved = false
local time = 0

local function index(r, c)
    return (r - 1) * GRID + c
end

local function check_solved()
    for i = 1, GRID*GRID - 1 do
        if tiles[i] ~= i then
            solved = false
            return
        end
    end
    solved = true
end

local function swap(_er, _ec, tr, tc)
    local i1, i2 = index(_er, _ec), index(tr, tc)
    tiles[i1], tiles[i2] = tiles[i2], tiles[i1]
    er, ec = tr, tc
end

local function neighbors(r, c)
    local n = {}
    if r > 1 then
        table.insert(n, {r-1, c})
    end
    if r < GRID then
        table.insert(n, {r+1, c})
    end
    if c > 1 then
        table.insert(n, {r, c-1})
    end
    if c < GRID then
        table.insert(n, {r, c+1})
    end
    return n
end

-- Perform legal random moves to ensure solvable state.
local function shuffle(count)
    is_shuffling = true
    for i = 1, count do
        local n = neighbors(er, ec)
        local choice = n[ love.math.random(#n) ]
        swap(er, ec, choice[1], choice[2])
    end
    is_shuffling = false
end

local function new_game(step)
    solved = false
    moves = 0
    tiles = {}
    for i = 1, GRID * GRID - 1 do
        tiles[i] = i
    end
    tiles[GRID * GRID] = 0
    er, ec = GRID, GRID
    shuffle(step or 200)
    time = 0
end

function _15.enter()
    print("[Pattern] enter")

    love.graphics.setFont(game.font_mono)
    new_game(300)
end

function _15.exit()
    love.graphics.setFont(game.font)
    print("[Pattern] exit")
end

function _15.update(dt)
    if not solved then
        time = time + dt
    end
end

local function tile_draw(x, y, w, h, number)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setColor(0, 0, 0)
    local txt = tostring(number)
    local tw = font:getWidth(txt)
    local th = font:getHeight()
    love.graphics.print(txt, x + (w-tw)/2, y + (h-th)/2)
end

function _15.draw()
    love.graphics.clear(0.95, 0.95, 0.95)
    for r = 1, GRID do
        for c = 1, GRID do
            local i = index(r, c)
            local x = game.screen_padding + (c - 1) * (TILE_SIZE + GAP)
            local y = game.screen_padding + (r - 1) * (TILE_SIZE + GAP)
            local v = tiles[i]
            if v ~= 0 then
                tile_draw(x, y, TILE_SIZE, TILE_SIZE, v)
            else
                -- draw empty slot
                love.graphics.setColor(0.85, 0.85, 0.85)
                love.graphics.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE)
            end
        end
    end

    -- UI area.
    local ux = 480
    local uy = 10
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Moves: " .. moves, ux, uy)
    love.graphics.print(string.format("Time: " .. math.floor(time)), ux, uy + 30)

    love.graphics.print("(r)eset", ux, uy + 60)
    love.graphics.print("(s)huffle", ux, uy + 90)
    if solved then
        love.graphics.setColor(0, 0, 1)
        love.graphics.print("SOLVED!", ux, uy + 120)
    end
end

local function try_move(r, c)
    if is_shuffling then return end

    local dr = math.abs(er - r)
    local dc = math.abs(ec - c)
    if (dr == 1 and dc == 0) or (dr == 0 and dc == 1) then
        swap(er, ec, r, c)
        moves = moves + 1
        check_solved()
    end
end

function _15.mousepressed(x, y, button)
    if button == 1 then
        local c = math.floor((x - 10) / (TILE_SIZE + GAP)) + 1
        local r = math.floor((y - 10) / (TILE_SIZE + GAP)) + 1
        if r >= 1 and r <= GRID and c >= 1 and c <= GRID then
            try_move(r, c)
        end
    end
end

function _15.mousereleased(x, y, button)
end

function _15.keypressed(key)
    if key == "r" then
        new_game(0)
    elseif key == "s" then
        new_game(300)
    elseif key == "escape" then
        fsm.pop()
    end
end

return _15
