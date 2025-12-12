local util = require("util")

local game = {}

-- Only used for displaying game title in home screen.
game.TITLE_FONT        = love.graphics.newFont(26, "mono")
game.TITLE_FONT_HEIGHT = game.TITLE_FONT:getHeight()
game.TITLE_WIDTH       = game.TITLE_FONT:getWidth(love.window.getTitle())
game.TITLE_FONT:setFilter("nearest")

-- General font setup.
-- NOTE: This is not constant. Add feature to change font later.
game.font        = love.graphics.newFont("fonts/FuzzyBubbles-Regular.ttf", 16)
game.font_height = game.font:getHeight()
game.font:setFilter("nearest")
love.graphics.setFont(game.font)

-- For Vimouto and ImoTerm.
game.font_mono        = love.graphics.newFont("fonts/roboto.ttf", 16)
game.font_mono_width  = game.font_mono:getWidth(".")
game.font_mono_height = game.font_mono:getHeight()
game.font_mono:setFilter("nearest")

game.SCREEN_PADDING = 10  -- NOTE: Vimouto and ImoTerm don't have this padding.
game.PADDING        = 5   -- For button, dialogue box, etc.

return util.strict(game)
