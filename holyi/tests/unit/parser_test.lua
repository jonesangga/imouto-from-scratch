local lust   = require("libraries/lust")
local lexer  = require("lexer")
local parser = require("parser")
local types  = require("types")

local TT, NT, IT = types.TT, types.NT, types.IT

local describe, it, expect = lust.describe, lust.it, lust.expect

describe("parse", function()
    it("simple", function()
        expect( parser(lexer("1;")) ).to.equal( {
            {tag = NT.EXPR_STMT, expr = {tag = NT.INT, type = IT.INT, val = 1}}
        } )
    end)

    it("binary", function()
        expect( parser(lexer("1 + 2;")) ).to.equal( {
            {tag = NT.EXPR_STMT,
            expr = {
                left = {tag = NT.INT, type = IT.INT, val = 1},
                op = TT.PLUS,
                right = {tag = NT.INT, type = IT.INT, val = 2},
                tag = NT.BINARY,
            }},
        } )
    end)
end)
