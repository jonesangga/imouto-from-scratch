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

-- Monkey patch
local real_loadTree = vimouto.loadTree
vimouto.loadTree = function() end

describe("tab binding", function()
    before(function()
        fake = {}
        vimouto:reset()
    end)

    it("toggle normal and tree mode", function()
        expect(vimouto.mode).to.equal("NORMAL")
        fsm.keypressed("tab")
        expect(vimouto.mode).to.equal("TREE")
        fsm.keypressed("tab")
        expect(vimouto.mode).to.equal("NORMAL")
    end)
end)

describe("j binding", function()
    before(function()
        fake = {}
        vimouto:reset()
    end)

    it("when there is just one entry", function()
        vimouto.tree.lines = {"line 1"}
        fsm.keypressed("tab")
        expect(vimouto.tree.cy).to.equal(1)
        fsm.keypressed("j")
        expect(vimouto.tree.cy).to.equal(1)
    end)

    it("when there is below entry", function()
        vimouto.tree.lines = {"line 1", "line 2"}
        fsm.keypressed("tab")
        expect(vimouto.tree.cy).to.equal(1)
        fsm.keypressed("j")
        expect(vimouto.tree.cy).to.equal(2)
    end)

    it("when at the last entry", function()
        vimouto.tree.lines = {"line 1", "line 2"}
        fsm.keypressed("tab")
        expect(vimouto.tree.cy).to.equal(1)
        fsm.keypressed("j")
        expect(vimouto.tree.cy).to.equal(2)
        fsm.keypressed("j")
        expect(vimouto.tree.cy).to.equal(2)
    end)
end)

describe("k binding", function()
    before(function()
        fake = {}
        vimouto:reset()
    end)

    it("when there is just one entry", function()
        vimouto.tree.lines = {"line 1"}
        fsm.keypressed("tab")
        expect(vimouto.tree.cy).to.equal(1)
        fsm.keypressed("k")
        expect(vimouto.tree.cy).to.equal(1)
    end)

    it("when there is below entry", function()
        vimouto.tree.lines = {"line 1", "line 2"}
        fsm.keypressed("tab")
        vimouto.tree.cy = 2
        fsm.keypressed("k")
        expect(vimouto.tree.cy).to.equal(1)
    end)

    it("when at the first entry", function()
        vimouto.tree.lines = {"line 1", "line 2"}
        fsm.keypressed("tab")
        vimouto.tree.cy = 2
        fsm.keypressed("k")
        expect(vimouto.tree.cy).to.equal(1)
        fsm.keypressed("k")
        expect(vimouto.tree.cy).to.equal(1)
    end)
end)

describe("space binding", function()
    before(function()
        fake = {}
        vimouto:reset()
    end)

    it("typical", function()
        vimouto.tree.lines = {"line 1"}
        fsm.keypressed("tab")
        expect(vimouto.mode).to.equal("TREE")
        fsm.keypressed("space")
        expect(vimouto.mode).to.equal("NORMAL")
        expect(vimouto.treeFocus).to.equal(false)
        fsm.keypressed("space")
        expect(vimouto.mode).to.equal("TREE")
    end)
end)

vimouto.loadTree = real_loadTree
love.keyboard.isDown = real_isDown
