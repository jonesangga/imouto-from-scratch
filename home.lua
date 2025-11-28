local game = require("game")
local fsm = require("fsm")
local ui = require("ui")
local audio = require("audio")
local character = require("character")
local wallpaper = require("wallpaper")
local ep1 = require("ep1")
local ep2 = require("ep2")
local ep3 = require("ep3")
local pattern = require("pattern")
local vimouto = require("vimouto")

local home = {
    name = "Home",
}

local imouto = nil
local mainMenu = nil
local stories = nil
local areas = nil
local current = nil
local wall = nil
local music = nil

function home.enter()
    print("[Home] enter")
    wall = wallpaper.new("patterns/pastel64/blue1.png")
    imouto = character.new("characters/ichinose-kotomi.png")

    stories = ui.Menu.new(10, 100, "left", {
        {
            "#1 Hajimari", function()
                print("[home] Button ep1 clicked!")
                fsm.push(ep1)
            end
        },
        {
            "#2 Nii-san no new hobby", function()
                print("[home] Button ep2 clicked!")
                fsm.push(ep2)
            end
        },
        {
            "#3 Write the future", function()
                print("[home] Button ep3 clicked!")
                fsm.push(ep3)
            end
        },
    })

    areas = ui.Menu.new(10, 100, "left", {
        {
            "Patterns", function()
                print("[home] Button Patterns clicked!")
                fsm.push(pattern)
            end
        },
        {
            "Vimouto", function()
                print("[home] Button Vimouto clicked!")
                fsm.push(vimouto)
            end
        },
    })

    mainMenu = ui.Radio.new(630, 100, "right", {
        {
            "Stories", function()
                print("[home] Button Stories clicked!")
                current = stories
            end
        },
        {
            "Areas", function()
                print("[home] Button Areas clicked!")
                current = areas
            end
        },
        {
            "Exit", function()
                print("[home] Button Exit clicked!")
                love.event.quit()
            end
        },
    })
    mainMenu:select(1)

    current = stories

    music = audio.new("audios/laur-you-are-my-irreplaceable-treasure.mp3", "stream")
    music:play()
end

function home.exit()
    print("[Home] exit")
end

-- Only called from fsm.pop().
function home.continueAudio()
    music:play()
end

-- Only called from fsm.push().
function home.pauseAudio()
    music:pause()
end

function home.update()
    mainMenu:update()
    current:update()
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
    mainMenu:draw()
    current:draw()
end

function home.mousepressed(x, y, button)
    mainMenu:mousepressed(x, y, button)
    current:mousepressed(x, y, button)
end

function home.mousereleased(x, y, button)
    mainMenu:mousereleased(x, y, button)
    current:mousereleased(x, y, button)
end

function home.keypressed(key, scancode, isrepeat)
end

return home
