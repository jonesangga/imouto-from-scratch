local lust = require("libraries/lust")
local tokenize = require("tokenize")
local parse = require("parse")
local types = require("types")

local list, quote, symbol = types.list, types.quote, types.symbol
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
        expect( parse(tokenize("a")) ).to.equal( {{ name = "a"}} )
        expect( parse(tokenize("+")) ).to.equal( {{ name = "+"}} )
        expect( parse(tokenize("a b +")) ).to.equal( {symbol("a"), symbol("b"), symbol("+")} )
    end)

    it("string", function()
        expect( parse(tokenize('""')) ).to.equal( {""} )
        expect( parse(tokenize('"so real"')) ).to.equal( {"so real"} )
        expect( parse(tokenize('"so \\"real"')) ).to.equal( {"so \"real"} )
        expect( parse(tokenize('"so \\\\real"')) ).to.equal( {"so \\real"} )
    end)

    it("quote", function()
        expect( parse(tokenize("'a")) ).to.equal( {{value = symbol("a")}} )
        expect( parse(tokenize("''a")) ).to.equal( {quote(quote(symbol("a")))} )
        expect( parse(tokenize("'(so real)")) ).to.equal( {quote(list {symbol("so"), symbol("real")})} )
    end)

    it("number", function()
        expect( parse(tokenize("12")) ).to.equal( {12} )
        expect( parse(tokenize("1 2 3")) ).to.equal( {1, 2, 3} )
    end)

    it("list", function()
        expect( parse(tokenize("()")) ).to.equal( {list {}} )
        expect( parse(tokenize("(1 2)")) ).to.equal( {list {1, 2}} )
        expect( parse(tokenize("(1 2 3)")) ).to.equal( {list {1, 2, 3}} )
        expect( parse(tokenize("(1 (2 3) (4 5))")) ).to.equal( {list {1, list {2, 3}, list {4, 5}}} )
        expect( parse(tokenize("(define x 2)")) ).to.equal( {list {symbol("define"), symbol("x"), 2}} )
    end)

    it("nested", function()
        expect( parse(tokenize("((a))")) ).to.equal( {list {list {symbol("a")}}} )
    end)

    it("error", function()
        expect( function() parse(tokenize("(")) end).to.fail.with("missing %)")
        expect( function() parse(tokenize(")")) end).to.fail.with("unexpected %)")
    end)
end)
