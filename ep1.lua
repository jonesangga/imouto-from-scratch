local game = require("game")
local fsm = require("fsm")
local ui = require("ui")
local character = require("character")
local wallpaper = require("wallpaper")

local ep1 = {
    name = "ep1",
}

local imouto = nil
local dialogue = nil
local wall = nil
local music = nil
local initialized = false

function ep1.enter()
    print("[ep1] enter")

    if not initialized then
        initialized = true
        wall = wallpaper.new("patterns/pastel64/blue3.png")
        imouto = character.new("characters/kanbe-kotori.png")
        music = love.audio.newSource("audio/ep1.mp3", "stream")
        music:setLooping(true)
        music:setVolume(1.0)

        dialogue = ui.Dialogue.new({
2, "Welcome, Ada. I created you as my imouto. Korekara mo yoroshiku onegaishimasu.",
1, "That is a really bad introduction, nii-san.",
2, "I am bad at communication.",
1, "Naze watashi wa 3D de wa nai no desu ka, nii-san? I don't even have face and hair, just a silhouette T_T.",
2, "I cannot do 3D. And I am really bad at drawing. I tried many times and give up. That makes me abandon this project many times.",
2, "So I decided to just take nice anime characters and edit that.",
1, "Kore de ii to omou yo, niisan. Tenshi mitai (^_^)",
1, "Watashi wa nansai desu ka?",
2, "Around middle school or high school.",
1, "Why did I speak Japanese in romaji?",
2, "I plan to support hiragana and katakana. I will learn how to do it later.",
1, "Why using lua?",
2, "Because it just works.",
1, "What will you do in this project?",
2, "I just do what idea I suddenly have. I don't want to overthink. I like to see the improvement through the time.",
2, "I promise to show you many interesting things.",
1, "Sasuga, nii-san (>_<).",
        })
    end

    music:play()
end

function ep1.exit()
    music:stop()
    dialogue:reset()
    print("[ep1] exit")
end

-- Only called from fsm.pop().
function ep1.continueAudio()
    music:play()
end

-- Only called from fsm.push().
function ep1.pauseAudio()
    music:pause()
end

function ep1.update(dt)
    dialogue:update(dt)
end

function ep1.draw()
    wall:draw()
    imouto:draw()
    dialogue:draw()
end

function ep1.mousepressed(x, y, button)
    dialogue:mousepressed(x, y, button)
end

function ep1.mousereleased(x, y, button)
end

-- TODO: Add confirmation dialogue?
function ep1.keypressed(key, scancode, isrepeat)
    if key == "w" then
        wall:browse()
    end
    if key == "q" then
        fsm.pop()
    end
end

return ep1
