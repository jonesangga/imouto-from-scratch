local game = require("game")
local fsm = require("fsm")
local ui = require("ui")
local character = require("character")
local wallpaper = require("wallpaper")
local ep1 = require("ep1")

local home = {
    name = "Home",
}

local imouto = nil
local menu = nil
local wall = nil
local music = nil

function home.enter()
    print("[Home] enter")
    wall = wallpaper.new("patterns/pastel64/blue1.png")
    imouto = character.new("characters/ichinose-kotomi.png")

    menu = ui.Menu.new(10, 100, {
        {
            "#1 Hajimari", function()
                print("[home] Button ep1 clicked!")
                fsm.push(ep1)
            end
        },
        {
            "Exit", function()
                print("[home] Button Exit clicked!")
                love.event.quit()
            end
        },
    })

    music = love.audio.newSource("audio/laur-you-are-my-irreplaceable-treasure.mp3", "stream")
    music:setLooping(true)
    music:setVolume(1.0)
    music:play()
end

function home.exit()
    print("[Home] exit")
end

-- Only called from fsm.pop().
function home.playAudio()
    music:play()
end

-- Only called from fsm.push().
function home.stopAudio()
    music:stop()
end

function home.update()
    menu:update()
end

function home.draw()
    wall:draw()

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", game.screenPadding,
                                    game.screenPadding,
                                    game.titleWidth + 2 * game.padding,
                                    game.titleFontHeight + 2 * game.padding)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(game.titleFont)
    love.graphics.print("Imouto From Scratch", 10 + game.padding, 10 + game.padding)

    imouto:draw()
    love.graphics.setFont(game.font)
    menu:draw()
end

function home.mousepressed(x, y, button)
    menu:mousepressed(x, y, button)
end

function home.mousereleased(x, y, button)
    menu:mousereleased(x, y, button)
end

function home.keypressed(key, scancode, isrepeat)
end

return home
