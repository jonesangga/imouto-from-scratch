local util = require("util")

local game = {}

-- Only used for displaying game title in home screen.
game.title_font        = love.graphics.newFont(26, "mono")
game.title_font_height = game.title_font:getHeight()
game.title_width       = game.title_font:getWidth(love.window.getTitle())
game.title_font:setFilter("nearest")

-- General font setup.
game.font        = love.graphics.newFont("fonts/FuzzyBubbles-Regular.ttf", 16)
game.font_height = game.font:getHeight()
game.font:setFilter("nearest")
love.graphics.setFont(game.font)

-- For Vimouto and ImoTerm.
game.font_mono        = love.graphics.newFont("fonts/roboto.ttf", 16)
game.font_mono_width  = game.font_mono:getWidth(".")
game.font_mono_height = game.font_mono:getHeight()
game.font_mono:setFilter("nearest")

game.screen_padding = 10  -- NOTE: Vimouto and ImoTerm don't have padding.
game.padding        = 5   -- For button, dialogue box, etc.

return util.strict(game)
