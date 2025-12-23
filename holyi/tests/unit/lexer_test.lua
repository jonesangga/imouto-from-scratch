local lust  = require("libraries/lust")
local lexer = require("lexer")
local TT    = require("types").TT

local describe, it, expect = lust.describe, lust.it, lust.expect

-- Helper.
local function t(type, val)
    return { type = type, val = val }
end

describe("lexer", function()
    it("empty", function()
        expect( lexer("") ).to.equal( {} )
        expect( lexer("    ") ).to.equal( {} )
    end)

    it("comment", function()
        expect( lexer("// this is a comment") ).to.equal( {} )
        expect( lexer("// this is a comment\n 123") ).to.equal( {t(TT.INT, 123)} )
        expect( lexer("123 // this is a comment\n 45") ).to.equal( {t(TT.INT, 123), t(TT.INT, 45)} )
    end)

    it("type", function()
        expect( lexer("Int") ).to.equal( {t(TT.TYPE, "Int")} )
        expect( lexer("Real") ).to.equal( {t(TT.TYPE, "Real")} )
    end)

    it("number", function()
        expect( lexer("123") ).to.equal( {t(TT.INT, 123)} )
        expect( lexer("123 45") ).to.equal( {t(TT.INT, 123), t(TT.INT, 45)} )
    end)

    it("string", function()
        expect( lexer('"real"') ).to.equal( {t(TT.STRING, "real")} )
    end)

    it("brackets", function()
        expect( lexer("(") ).to.equal( {t(TT.LPAREN)} )
        expect( lexer(")") ).to.equal( {t(TT.RPAREN)} )
        expect( lexer("{") ).to.equal( {t(TT.LBRACE)} )
        expect( lexer("}") ).to.equal( {t(TT.RBRACE)} )
    end)

    it("arithmetics", function()
        expect( lexer("+") ).to.equal( {t(TT.PLUS)} )
        expect( lexer("-") ).to.equal( {t(TT.MINUS)} )
        expect( lexer("*") ).to.equal( {t(TT.STAR)} )
        expect( lexer("/") ).to.equal( {t(TT.SLASH)} )
    end)

    it("comparison", function()
        expect( lexer("!") ).to.equal( {t(TT.NOT)} )
        expect( lexer("!=") ).to.equal( {t(TT.NOT_EQ)} )
        expect( lexer("=") ).to.equal( {t(TT.EQ)} )
        expect( lexer("==") ).to.equal( {t(TT.EQ_EQ)} )
        expect( lexer("<") ).to.equal( {t(TT.LESS)} )
        expect( lexer("<=") ).to.equal( {t(TT.LESS_EQ)} )
        expect( lexer(">") ).to.equal( {t(TT.GREATER)} )
        expect( lexer(">=") ).to.equal( {t(TT.GREATER_EQ)} )
    end)

    it("others", function()
        expect( lexer(";") ).to.equal( {t(TT.SEMICOLON)} )
        expect( lexer(",") ).to.equal( {t(TT.COMMA)} )
        expect( lexer(".") ).to.equal( {t(TT.DOT)} )
        expect( lexer("..") ).to.equal( {t(TT.DOT2)} )
    end)

    it("show", function()
        expect( lexer("show 2;") ).to.equal( {
            t(TT.SHOW),
            t(TT.INT, 2),
            t(TT.SEMICOLON),
        } )
    end)

    it("keywords", function()
        expect( lexer("else") ).to.equal( {t(TT.ELSE)} )
        expect( lexer("false") ).to.equal( {t(TT.FALSE)} )
        expect( lexer("for") ).to.equal( {t(TT.FOR)} )
        expect( lexer("if") ).to.equal( {t(TT.IF)} )
        expect( lexer("return") ).to.equal( {t(TT.RETURN)} )
        expect( lexer("true") ).to.equal( {t(TT.TRUE)} )
        expect( lexer("while") ).to.equal( {t(TT.WHILE)} )
    end)

    it("&& ||", function()
        expect( lexer("&&") ).to.equal( {t(TT.AMP2)} )
        expect( lexer("||") ).to.equal( {t(TT.PIPE2)} )
    end)
end)
