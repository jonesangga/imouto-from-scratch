local lust = require("libraries/lust")
local types = require("types")

local describe, it, expect = lust.describe, lust.it, lust.expect
local EMPTY, pair, list, char = types.EMPTY, types.pair, types.list, types.char

local function t(type, value, line)
    return { type = type, value = value, line = line }
end

describe("types", function()
    it("EMPTY", function()
        expect( EMPTY == EMPTY ).to.equal( true )
        expect( EMPTY == nil ).to.equal( false )
        expect( EMPTY == {} ).to.equal( false )
        expect( tostring(EMPTY) ).to.equal( "()" )
    end)

    it("pair", function()
        local p = pair(1, 2)
        expect( p ).to.equal( pair(1, 2) )
        expect( tostring(p) ).to.equal( "(1 . 2)" )
    end)

    it("pair EMPTY", function()
        local p = pair(1, EMPTY)
        expect( p ).to.equal( pair(1, EMPTY) )
        expect( tostring(p) ).to.equal( "(1)" )
    end)

    it("pair string", function()
        local p = pair("so", "real")
        expect( p ).to.equal( pair("so", "real") )
        expect( tostring(p) ).to.equal( "(so . real)" )
    end)

    it("pair nested", function()
        local p = pair(1, pair(2, 3))
        expect( p.car ).to.equal( 1 )
        expect( p.cdr ).to.equal( pair(2, 3) )
        expect( tostring(p) ).to.equal( "(1 2 . 3)" )
    end)

    it("list", function()
        local l = list {1, 2, 3}
        expect( l ).to.equal( list {1, 2, 3} )
        expect( tostring(l) ).to.equal( "(1 2 3)" )
    end)

    it("list nested", function()
        local l = list {1, list {2, 3}, 4}
        expect( tostring(l) ).to.equal( "(1 (2 3) 4)" )
    end)

    it("char alphabet", function()
        local l = char("#\\a")
        expect( l.ch ).to.equal( ("a"):byte(1) )
        expect( tostring(l) ).to.equal( "#\\a" )
    end)

    it("char non alphabet", function()
        local l = char("#\\;")
        expect( l.ch ).to.equal( (";"):byte(1) )
        expect( tostring(l) ).to.equal( "#\\;" )
    end)

    it("char named space", function()
        local l = char("#\\space")
        expect( l.ch ).to.equal( (" "):byte(1) )
        expect( tostring(l) ).to.equal( "#\\space" )
    end)

    it("char named newline", function()
        local l = char("#\\newline")
        expect( l.ch ).to.equal( ("\n"):byte(1) )
        expect( tostring(l) ).to.equal( "#\\newline" )
    end)

    it("char invalid", function()
        expect( function() char("#\\real") end ).to.fail.with( "unknown named character" )
    end)
end)
