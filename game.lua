local game = {}

function game.init()
    -- Only used for displaying game title in home screen.
    game.titleFont       = love.graphics.newFont(26, "mono")
    game.titleFontHeight = game.titleFont:getHeight()
    game.titleWidth      = game.titleFont:getWidth(love.window.getTitle())
    game.titleFont:setFilter("nearest")

    -- General font setup.
    game.font       = love.graphics.newFont(16, "mono")
    game.fontHeight = game.font:getHeight()
    game.font:setFilter("nearest")

    game.screenPadding = 10
    game.padding       = 5   -- For button, dialogue box, etc.
end

return game
