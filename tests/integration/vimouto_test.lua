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
    return fake[k] ~= nil
end

love.graphics.setDefaultFilter("nearest", "nearest")  -- Nearest neighbor filtering for pixel art.
love.graphics.setBackgroundColor(1, 1, 1)
love.keyboard.setKeyRepeat(true)

fsm.push(vimouto)

describe("i binding", function()
    before(function()
        fake = {}
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
        fake = {}
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

describe("o binding", function()
    before(function()
        fake = {}
        vimouto:reset()
    end)

    it("normal become insert mode", function()
        expect(vimouto.mode).to.equal("NORMAL")
        fsm.keypressed("o")

        expect(vimouto.mode).to.equal("INSERT")
        expect(vimouto.active.blocked_chars["o"]).to.equal(true)
        expect(vimouto.active.cy).to.equal(2)
    end)

    it("start at beginning", function()
        vimouto.active.lines = {"a test line"}
        vimouto.active.cx = 4
        fsm.keypressed("o")

        expect(vimouto.mode).to.equal("INSERT")
        expect(vimouto.active.cx).to.equal(1)
        expect(vimouto.active.cy).to.equal(2)
    end)
end)

describe("O binding", function()
    before(function()
        fake = {}
        vimouto:reset()
    end)

    it("normal become insert mode", function()
        expect(vimouto.mode).to.equal("NORMAL")
        fake.lshift = true
        fsm.keypressed("o")

        expect(vimouto.mode).to.equal("INSERT")
        expect(vimouto.active.blocked_chars["O"]).to.equal(true)
        expect(#vimouto.active.lines).to.equal(2)
    end)

    it("start at beginning", function()
        vimouto.active.lines = {"a test line"}
        vimouto.active.cx = 4
        fake.lshift = true
        fsm.keypressed("o")

        expect(vimouto.mode).to.equal("INSERT")
        expect(vimouto.active.blocked_chars["O"]).to.equal(true)
        expect(vimouto.active.cx).to.equal(1)
    end)
end)

describe("a binding", function()
    before(function()
        fake = {}
        vimouto:reset()
    end)

    it("empty line", function()
        expect(vimouto.mode).to.equal("NORMAL")
        fsm.keypressed("a")

        expect(vimouto.mode).to.equal("INSERT")
        expect(vimouto.active.blocked_chars["a"]).to.equal(true)
    end)

    it("non empty line", function()
        vimouto.active.lines = {"a test line"}
        vimouto.active.cx = 4
        fsm.keypressed("a")

        expect(vimouto.mode).to.equal("INSERT")
        expect(vimouto.active.cx).to.equal(5)
    end)
end)

describe("A binding", function()
    before(function()
        fake = {}
        vimouto:reset()
    end)

    it("empty line", function()
        expect(vimouto.mode).to.equal("NORMAL")
        fake.lshift = true
        fsm.keypressed("a")

        expect(vimouto.mode).to.equal("INSERT")
        expect(vimouto.active.blocked_chars["A"]).to.equal(true)
        expect(vimouto.active.cx).to.equal(1)
    end)

    it("start at beginning", function()
        vimouto.active.lines = {"a test line"}
        vimouto.active.cx = 4
        fake.lshift = true
        fsm.keypressed("a")

        expect(vimouto.mode).to.equal("INSERT")
        expect(vimouto.active.blocked_chars["A"]).to.equal(true)
        expect(vimouto.active.cx).to.equal(12)
    end)
end)

love.keyboard.isDown = real_isDown
