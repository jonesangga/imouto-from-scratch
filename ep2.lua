local game = require("game")
local fsm = require("fsm")
local ui = require("ui")
local character = require("character")
local wallpaper = require("wallpaper")

local ep2 = {
    name = "ep2",
}

local imouto = nil
local dialogue = nil
local wall = nil
local music = nil
local initialized = false

function ep2.enter()
    print("[ep2] enter")

    if not initialized then
        initialized = true
        wall = wallpaper.new("patterns/neocities/pattern33.png")
        imouto = character.new("characters/kasugano-sora.png")
        music = love.audio.newSource("audio/clannad-track-6.mp3", "stream")
        music:setLooping(true)
        music:setVolume(1.0)

        dialogue = ui.Dialogue.new({
1, "Nii-san, nani shiteru no?",
2, "Suddenly I have new hobby: collecting repeated background pattern. I don't know what people call that.",
2, "I see many of that in neocities sites.",
1, "What will you do with your collection?",
2, "I added new feature where you can choose pattern to be used as a background.",
1, "Can I try?",
2, "Sure, press w to open the wallpaper dialogue. Choose anything and see it changing live.",
1, "Wow sugoi, nii-san (>_<). I really like this.",
2, "Not only for cute pattern, this also looks good for silly pattern.",
1, "Hontou da.",
1, "Are you planning to use this type of background to all episodes?",
2, "Of course no, I have other plans, like using shader and cretive coding.",
1, "I cannot wait to see it",
        })
    end

    music:play()
end

function ep2.exit()
    music:stop()
    dialogue:reset()
    print("[ep2] exit")
end

function ep2.update(dt)
    dialogue:update(dt)
end

function ep2.draw()
    wall:draw()
    imouto:draw()
    dialogue:draw()
end

function ep2.mousepressed(x, y, button)
    dialogue:mousepressed(x, y, button)
end

function ep2.mousereleased(x, y, button)
end

-- TODO: Add confirmation dialogue?
function ep2.keypressed(key, scancode, isrepeat)
    if key == "w" then
        wall:browse()
    end
    if key == "q" then
        fsm.pop()
    end
end

return ep2
