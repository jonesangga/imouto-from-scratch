local game = require("game")
local buffer = require("vimouto/buffer")

local vimouto = {
    name = "vimouto",
}

local buf = nil

function vimouto.enter()
    print("[vimouto] enter")
    love.graphics.setFont(game.fontMono)
    buf = buffer.new()
end

function vimouto.exit()
    print("[vimouto] exit")
end

function vimouto.update(dt)
    buf:update(dt)
end

function vimouto.draw()
    buf:draw()
end

function vimouto.textinput(t)
    buf:textinput(t)
end

function vimouto.keypressed(key)
    buf:keypressed(key)
end

function vimouto.mousepressed(x, y, button)
end

function vimouto.mousereleased(x, y, button)
end

return vimouto
