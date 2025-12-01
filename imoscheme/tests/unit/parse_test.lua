local lust = require("libraries/lust")
local tokenize = require("tokenize")
local parse = require("parse")
local types = require("types")

local List, Quote, Symbol = types.List, types.Quote, types.Symbol
local describe, it, expect = lust.describe, lust.it, lust.expect

describe("parse", function()
    it("empty", function()
        expect( parse(tokenize("")) ).to.equal( {} )
        expect( parse(tokenize("    ")) ).to.equal( {} )
    end)

    it("boolean", function()
        expect( parse(tokenize("#t")) ).to.equal( {true} )
        expect( parse(tokenize("#f")) ).to.equal( {false} )
    end)

    it("symbol", function()
        expect( parse(tokenize("a")) ).to.equal( {{type = "symbol", name = "a"}} )
        expect( parse(tokenize("+")) ).to.equal( {{type = "symbol", name = "+"}} )
        expect( parse(tokenize("a b +")) ).to.equal( {Symbol.new("a"), Symbol.new("b"), Symbol.new("+")} )
    end)

    it("string", function()
        expect( parse(tokenize('""')) ).to.equal( {""} )
        expect( parse(tokenize('"so real"')) ).to.equal( {"so real"} )
        expect( parse(tokenize('"so \\"real"')) ).to.equal( {"so \"real"} )
        expect( parse(tokenize('"so \\\\real"')) ).to.equal( {"so \\real"} )
    end)

    it("quote", function()
        expect( parse(tokenize("'a")) ).to.equal( {{type = "quote", value = Symbol.new("a")}} )
        expect( parse(tokenize("''a")) ).to.equal( {Quote.new(Quote.new(Symbol.new("a")))} )
        expect( parse(tokenize("'(so real)")) ).to.equal( {Quote.new(List.from {Symbol.new("so"), Symbol.new("real")})} )
    end)

    it("number", function()
        expect( parse(tokenize("12")) ).to.equal( {12} )
        expect( parse(tokenize("1 2 3")) ).to.equal( {1, 2, 3} )
    end)

    it("list", function()
        expect( parse(tokenize("()")) ).to.equal( {List.from{}} )
        expect( parse(tokenize("(1 2)")) ).to.equal( {List.from {1, 2}} )
        expect( parse(tokenize("(1 2 3)")) ).to.equal( {List.from {1, 2, 3}} )
        expect( parse(tokenize("(1 (2 3) (4 5))")) ).to.equal( {List.from {1, List.from {2, 3}, List.from {4, 5}}} )
        expect( parse(tokenize("(define x 2)")) ).to.equal( {List.from {Symbol.new("define"), Symbol.new("x"), 2}} )
    end)

    it("nested", function()
        expect( parse(tokenize("((a))")) ).to.equal( {List.from {List.from {Symbol.new("a")}}} )
    end)

    it("error", function()
        expect( function() parse(tokenize("(")) end).to.fail.with("missing %)")
        expect( function() parse(tokenize(")")) end).to.fail.with("unexpected %)")
    end)
end)
