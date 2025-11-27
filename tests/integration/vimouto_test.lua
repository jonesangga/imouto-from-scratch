local lust = require("libraries/lust")
local describe, it, expect, before = lust.describe, lust.it, lust.expect, lust.before

local game = require("game")
local fsm = require("fsm")
local vimouto = require("vimouto")

local real_isDown = love.keyboard.isDown
local fake = {
    lshift = false,
    rshift = false,
}

love.keyboard.isDown = function(k)
    if fake[k] ~= nil then
        return fake[k]
    end
    error("no key: " .. k)
end

love.graphics.setDefaultFilter("nearest", "nearest")  -- Nearest neighbor filtering for pixel art.
love.graphics.setBackgroundColor(1, 1, 1)
love.keyboard.setKeyRepeat(true)

game.init()
fsm.push(vimouto)

describe("i binding", function()
    before(function()
        vimouto:reset()
    end)

    it("normal become insert mode", function()
        expect(vimouto.mode).to.equal("NORMAL")
        fsm.keypressed("i")

        expect(vimouto.mode).to.equal("INSERT")
        expect(vimouto.active.blocked_chars["i"]).to.equal(true)
    end)
end)

describe("I binding", function()
    before(function()
        vimouto:reset()
    end)

    it("normal become insert mode", function()
        expect(vimouto.mode).to.equal("NORMAL")
        fake.lshift = true
        fsm.keypressed("i")

        expect(vimouto.mode).to.equal("INSERT")
        expect(vimouto.active.blocked_chars["i"]).to.equal(nil)
        expect(vimouto.active.blocked_chars["I"]).to.equal(true)
    end)

    it("start at beginning", function()
        vimouto.active.lines = {"a test line"}
        vimouto.active.cx = 4
        fake.lshift = true
        fsm.keypressed("i")

        expect(vimouto.mode).to.equal("INSERT")
        expect(vimouto.active.blocked_chars["I"]).to.equal(true)
        expect(vimouto.active.cx).to.equal(1)
    end)
end)

love.keyboard.isDown = real_isDown
