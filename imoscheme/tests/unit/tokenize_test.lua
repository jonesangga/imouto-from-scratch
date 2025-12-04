local lust = require("libraries/lust")
local tokenize = require("tokenize")

local describe, it, expect = lust.describe, lust.it, lust.expect

local function t(type, value, line)
    return { type = type, value = value, line = line }
end

describe("tokenizer", function()
    it("empty", function()
        expect( tokenize("") ).to.equal( {} )
        expect( tokenize("    ") ).to.equal( {} )
    end)

    it("number", function()
        expect( tokenize("123") ).to.equal( {t("number", "123", 1)} )
        expect( tokenize("123.45") ).to.equal( {t("number", "123.45", 1)} )
        expect( tokenize("+123") ).to.equal( {t("number", "+123", 1)} )
        expect( tokenize("-123") ).to.equal( {t("number", "-123", 1)} )
    end)

    it("char", function()
        expect( tokenize("#\\a") ).to.equal( {t("char", "#\\a", 1)} )
        expect( tokenize("#\\;") ).to.equal( {t("char", "#\\;", 1)} )
        expect( tokenize("#\\space") ).to.equal( {t("char", "#\\space", 1)} )
        expect( tokenize("#\\real") ).to.equal( {t("char", "#\\real", 1)} )
        expect( tokenize("#\\newline ") ).to.equal( {t("char", "#\\newline", 1)} )
        expect( tokenize("#\\newline(") ).to.equal( {t("char", "#\\newline", 1), t("lparen", "(", 1)} )
    end)

    it("not char", function()
        expect( tokenize("#\\ ") ).to.equal( {t("symbol", "#\\", 1)} )
    end)

    it("symbol", function()
        expect( tokenize("a") ).to.equal( {t("symbol", "a", 1)} )
        expect( tokenize("define") ).to.equal( {t("symbol", "define", 1)} )
        expect( tokenize("-") ).to.equal( {t("symbol", "-", 1)} )
    end)

    it("parens", function()
        expect( tokenize("(") ).to.equal( {t("lparen", "(", 1)} )
        expect( tokenize(")") ).to.equal( {t("rparen", ")", 1)} )
    end)

    it("boolean", function()
        expect( tokenize("#t") ).to.equal( {t("boolean", "#t", 1)} )
        expect( tokenize("#f") ).to.equal( {t("boolean", "#f", 1)} )
    end)

    it("list", function()
        expect( tokenize("(+ 1 2)") ).to.equal( {
            t("lparen", "(", 1),
            t("symbol", "+", 1),
            t("number", "1", 1),
            t("number", "2", 1),
            t("rparen", ")", 1),
        } )
    end)

    it("nested list", function()
        expect( tokenize("(+ 1 (* 2 3))") ).to.equal( {
            t("lparen", "(", 1),
            t("symbol", "+", 1),
            t("number", "1", 1),
            t("lparen", "(", 1),
            t("symbol", "*", 1),
            t("number", "2", 1),
            t("number", "3", 1),
            t("rparen", ")", 1),
            t("rparen", ")", 1),
        } )
    end)

    it("newline", function()
        expect( tokenize("(\n())") ).to.equal( {
            t("lparen", "(", 1),
            t("lparen", "(", 2),
            t("rparen", ")", 2),
            t("rparen", ")", 2),
        } )
    end)

    it("string", function()
        expect( tokenize('""') ).to.equal( {t("string", "", 1)} )
        expect( tokenize('"so real"') ).to.equal( {t("string", "so real", 1)} )
    end)

    it("escape sequence in string", function()
        expect( tokenize('"so \nreal"') ).to.equal( {t("string", "so \nreal", 1)} )
        expect( tokenize('"so \treal"') ).to.equal( {t("string", "so \treal", 1)} )
        expect( tokenize('"so \\"real"') ).to.equal( {t("string", "so \"real", 1)} )
        expect( tokenize('"so \\\\ real"') ).to.equal( {t("string", "so \\ real", 1)} )
    end)

    it("error unterminated string", function()
        expect( function() tokenize('"so real') end ).to.fail.with("unterminated string")
    end)

    it("quote", function()
        expect( tokenize("'a") ).to.equal( {t("quote", "'", 1), t("symbol", "a", 1)} )
        expect( tokenize("''a") ).to.equal( {t("quote", "'", 1), t("quote", "'", 1), t("symbol", "a", 1)} )
        expect( tokenize("'(so real)") ).to.equal( {
            t("quote", "'", 1),
            t("lparen", "(", 1),
            t("symbol", "so", 1),
            t("symbol", "real", 1),
            t("rparen", ")", 1),
        } )
    end)
end)
