local lust   = require("libraries/lust")
local lexer  = require("lexer")
local parser = require("parser")
local TT = require("types").TT
local NT = require("types").NT

local describe, it, expect = lust.describe, lust.it, lust.expect

describe("parse", function()
    it("simple", function()
        expect( parser(lexer("1;")) ).to.equal( {
            {tag = NT.EXPR_STMT, expr = {tag = NT.INT, val = 1}}
        } )
    end)

    it("binary", function()
        expect( parser(lexer("1 + 2;")) ).to.equal( {
            {tag = NT.EXPR_STMT,
            expr = {
                left = {tag = NT.INT, val = 1},
                op = TT.PLUS,
                right = {tag = NT.INT, val = 2},
                tag = NT.BINARY,
            }},
        } )
    end)
end)
