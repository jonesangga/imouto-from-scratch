local lust = require("libraries/lust")
local parser = require("parser")
local types = require("types")

local List, Symbol = types.List, types.Symbol
local describe, it, expect = lust.describe, lust.it, lust.expect

describe("parser", function()
    it("empty", function()
        expect( parser("") ).to.equal( {} )
        expect( parser("    ") ).to.equal( {} )
    end)

    it("boolean", function()
        expect( parser("#t") ).to.equal( {true} )
        expect( parser("#f") ).to.equal( {false} )
    end)

    it("symbol", function()
        expect( parser("a") ).to.equal( {{type = "symbol", name = "a"}} )
        expect( parser("+") ).to.equal( {{type = "symbol", name = "+"}} )
        expect( parser("a b +") ).to.equal( {Symbol.new("a"), Symbol.new("b"), Symbol.new("+")} )
    end)

    it("number", function()
        expect( parser("12") ).to.equal( {12} )
        expect( parser("1 2 3") ).to.equal( {1, 2, 3} )
    end)

    it("list", function()
        expect( parser("()") ).to.equal( {List.from{}} )
        expect( parser("(1 2)") ).to.equal( {List.from {1, 2}} )
        expect( parser("(1 2 3)") ).to.equal( {List.from {1, 2, 3}} )
        expect( parser("(1 (2 3) (4 5))") ).to.equal( {List.from {1, List.from {2, 3}, List.from {4, 5}}} )
        expect( parser("(define x 2)") ).to.equal( {List.from {Symbol.new("define"), Symbol.new("x"), 2}} )
    end)

    it("nested", function()
        expect( parser("((a))") ).to.equal( {List.from {List.from {Symbol.new("a")}}} )
    end)

    it("error", function()
        expect( function() parser("(") end).to.fail.with("missing %)")
        expect( function() parser(")") end).to.fail.with("unexpected %)")
    end)
end)
