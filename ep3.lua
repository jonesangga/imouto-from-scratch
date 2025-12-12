local game = require("game")
local fsm = require("fsm")
local ui = require("ui")
local audio = require("audio")
local character = require("character")
local wallpaper = require("wallpaper")
local vimouto = require("vimouto")

local ep3 = {
    name = "ep3",
}

local imouto = nil
local dialogue = nil
local wall = nil
local music = nil
local initialized = false

function ep3.enter()
    print("[ep3] enter")

    if not initialized then
        initialized = true
        wall = wallpaper.new("patterns/free/p1.png")
        imouto = character.new("characters/kasugano-sora.png")
        music = audio.new("audios/kioku.mp3", "stream")

        dialogue = ui.Dialogue.new({
1, "Nii-san, it's been a while since the last story. What happened?",
2, "I was building a text editor for you called Vimouto. Actually, I am behind schedule.",
1, "Yay. Now I can write something. How to open it?",
2, "Press v to open it. To quit do :q",
1, "This is really nice!",
2, "What took the most time was creating the story related to vimouto.",
2, "I tried hard to create scenarios for how you might use the editor. Some I have been thinking of: you want to write a book, you want to write a diary, you want to create a wiki or personal knowledge management.",
2, "But none of that was actually fun. I had a fever because of this.",
1, "I have an idea, nii-san. What if I write the future?",
2, "Dou iu imi?",
1, "I will write a diary of my future days, and nii-san has to make it happen.",
2, "So, it is like a challenge?",
1, "Yes. Saa, kaite iru yo",
1, "... (writing)",
1, "Done. You can read it, nii-san.",
        })
    end

    music:play()
end

function ep3.exit()
    music:stop()
    dialogue:reset()
    print("[ep3] exit")
end

-- Only called from fsm.pop().
function ep3.continueAudio()
    music:play()
end

-- Only called from fsm.push().
function ep3.pauseAudio()
    music:pause()
end

function ep3.update(dt)
    dialogue:update(dt)
end

function ep3.draw()
    wall:draw()
    imouto:draw()
    dialogue:draw()
end

function ep3.mousepressed(x, y, button)
    dialogue:mousepressed(x, y, button)
end

function ep3.mousereleased(x, y, button)
end

-- TODO: Add confirmation dialogue?
function ep3.keypressed(key, scancode, isrepeat)
    if key == "w" then
        wall:browse()
    end
    if key == "v" then
        fsm.push(vimouto)
    end
    if key == "escape" then
        fsm.pop()
    end
end

return ep3
