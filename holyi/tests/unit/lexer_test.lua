local lust  = require("libraries/lust")
local lexer = require("lexer")
local TT    = require("types").TT

local describe, it, expect = lust.describe, lust.it, lust.expect

-- Helper.
local function t(type, value)
    return { type = type, val = value }
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

    it("boolean", function()
        expect( lexer("true") ).to.equal( {t(TT.TRUE, "true")} )
        expect( lexer("false") ).to.equal( {t(TT.FALSE, "false")} )
    end)

    it("string", function()
        expect( lexer('"real"') ).to.equal( {t(TT.STRING, "real")} )
    end)

    it("parens", function()
        expect( lexer("(") ).to.equal( {t(TT.LPAREN)} )
        expect( lexer(")") ).to.equal( {t(TT.RPAREN)} )
    end)

    it("braces", function()
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
    end)

    it("println", function()
        expect( lexer("println 2;") ).to.equal( {
            t(TT.PRINTLN, "println"),
            t(TT.INT, 2),
            t(TT.SEMICOLON),
        } )
    end)

    it("if else", function()
        expect( lexer("if") ).to.equal( {t(TT.IF, "if")} )
    end)
end)
