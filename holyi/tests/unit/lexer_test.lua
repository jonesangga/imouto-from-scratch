local lust  = require("libraries/lust")
local lexer = require("lexer")
local TT    = require("types").TT

local describe, it, expect = lust.describe, lust.it, lust.expect

-- Helper.
local function t(type, val, line)
    return { type = type, val = val, line = line }
end

describe("lexer", function()
    it("empty", function()
        expect( lexer("") ).to.equal( {} )
        expect( lexer("    ") ).to.equal( {} )
        expect( lexer("a\nb\nc\nd") ).to.equal( {
            t(TT.IDENT, "a", 1),
            t(TT.IDENT, "b", 2),
            t(TT.IDENT, "c", 3),
            t(TT.IDENT, "d", 4),
        } )
    end)

    it("comment", function()
        expect( lexer("// this is a comment") ).to.equal( {} )
        expect( lexer("// this is a comment\n 123") ).to.equal( {t(TT.INT, 123, 2)} )
        expect( lexer("123 // this is a comment\n 45") ).to.equal( {t(TT.INT, 123, 1), t(TT.INT, 45, 2)} )
    end)

    it("type", function()
        expect( lexer("Int") ).to.equal( {t(TT.TYPE, "Int", 1)} )
        expect( lexer("Real") ).to.equal( {t(TT.TYPE, "Real", 1)} )
    end)

    it("number", function()
        expect( lexer("123") ).to.equal( {t(TT.INT, 123, 1)} )
        expect( lexer("123 45") ).to.equal( {t(TT.INT, 123, 1), t(TT.INT, 45, 1)} )
    end)

    it("string", function()
        expect( lexer('"real"') ).to.equal( {t(TT.STRING, "real", 1)} )
    end)

    it("brackets", function()
        expect( lexer("(") ).to.equal( {t(TT.LPAREN, nil, 1)} )
        expect( lexer(")") ).to.equal( {t(TT.RPAREN, nil, 1)} )
        expect( lexer("{") ).to.equal( {t(TT.LBRACE, nil, 1)} )
        expect( lexer("}") ).to.equal( {t(TT.RBRACE, nil, 1)} )
    end)

    it("arithmetics", function()
        expect( lexer("+") ).to.equal( {t(TT.PLUS, nil, 1)} )
        expect( lexer("-") ).to.equal( {t(TT.MINUS, nil, 1)} )
        expect( lexer("*") ).to.equal( {t(TT.STAR, nil, 1)} )
        expect( lexer("/") ).to.equal( {t(TT.SLASH, nil, 1)} )
    end)

    it("comparison", function()
        expect( lexer("!") ).to.equal( {t(TT.NOT, nil, 1)} )
        expect( lexer("!=") ).to.equal( {t(TT.NOT_EQ, nil, 1)} )
        expect( lexer("=") ).to.equal( {t(TT.EQ, nil, 1)} )
        expect( lexer("==") ).to.equal( {t(TT.EQ_EQ, nil, 1)} )
        expect( lexer("<") ).to.equal( {t(TT.LESS, nil, 1)} )
        expect( lexer("<=") ).to.equal( {t(TT.LESS_EQ, nil, 1)} )
        expect( lexer(">") ).to.equal( {t(TT.GREATER, nil, 1)} )
        expect( lexer(">=") ).to.equal( {t(TT.GREATER_EQ, nil, 1)} )
    end)

    it("others", function()
        expect( lexer(";") ).to.equal( {t(TT.SEMICOLON, nil, 1)} )
        expect( lexer(",") ).to.equal( {t(TT.COMMA, nil, 1)} )
        expect( lexer(".") ).to.equal( {t(TT.DOT, nil, 1)} )
        expect( lexer("..") ).to.equal( {t(TT.DOT2, nil, 1)} )
    end)

    it("show", function()
        expect( lexer("show 2;") ).to.equal( {
            t(TT.SHOW, nil, 1),
            t(TT.INT, 2, 1),
            t(TT.SEMICOLON, nil, 1),
        } )
    end)

    it("keywords", function()
        expect( lexer("else") ).to.equal( {t(TT.ELSE, nil, 1)} )
        expect( lexer("false") ).to.equal( {t(TT.FALSE, nil, 1)} )
        expect( lexer("for") ).to.equal( {t(TT.FOR, nil, 1)} )
        expect( lexer("if") ).to.equal( {t(TT.IF, nil, 1)} )
        expect( lexer("return") ).to.equal( {t(TT.RETURN, nil, 1)} )
        expect( lexer("true") ).to.equal( {t(TT.TRUE, nil, 1)} )
        expect( lexer("while") ).to.equal( {t(TT.WHILE, nil, 1)} )
    end)

    it("&& ||", function()
        expect( lexer("&&") ).to.equal( {t(TT.AMP2, nil, 1)} )
        expect( lexer("||") ).to.equal( {t(TT.PIPE2, nil, 1)} )
    end)
end)
