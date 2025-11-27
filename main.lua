local game = require("game")
local fsm = require("fsm")
local home = require("home")

-- Uncomment to test the state immediately.
-- local ep1 = require("ep1")
-- local ep2 = require("ep2")
-- local pattern = require("pattern")
-- local vimouto = require("vimouto")

function love.load(args)
    if #args > 0 and args[1] == "test" then
        require("tests/unit/util_test")
        require("tests/integration/vimouto_test")
        os.exit()
    end

    love.graphics.setDefaultFilter("nearest", "nearest")  -- Nearest neighbor filtering for pixel art.
    love.graphics.setBackgroundColor(1, 1, 1)
    love.keyboard.setKeyRepeat(true)

    game.init()
    fsm.push(home)

    -- Uncomment to test the state immediately.
    -- fsm.push(ep1)
    -- fsm.push(ep2)
    -- fsm.push(pattern)
    -- fsm.push(vimouto)
end

function love.update(dt)
    fsm.update(dt)
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    fsm.draw()
end

function love.mousepressed(x, y, button)
    fsm.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    fsm.mousereleased(x, y, button)
end

function love.textinput(t)
    fsm.textinput(t)
end

function love.keypressed(key, scancode, isrepeat)
    fsm.keypressed(key, scancode, isrepeat)
end
