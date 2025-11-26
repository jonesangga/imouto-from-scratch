local lust = require("libraries/lust")
local describe, it, expect = lust.describe, lust.it, lust.expect

local util = require("util")

describe('util.getFileNames', function()
    it('only names', function()
        local files = util.getFileNames("tests/unit/testdir")
        expect(files).to.equal({ "test1.txt", "test2.txt", "test3" })
    end)

    it('full path', function()
        local files = util.getFileNames("tests/unit/testdir", true)
        expect(files).to.equal({ "tests/unit/testdir/test1.txt", "tests/unit/testdir/test2.txt", "tests/unit/testdir/test3" })
    end)
end)

describe('util.splitLines', function()
    it("common case", function()
        local s = "a b\n\nc d\ne f"
        local lines = util.splitLines(s)
        expect(lines).to.equal({ "a b", "", "c d", "e f" })
    end)

    it("empty string", function()
        local s = ""
        local lines = util.splitLines(s)
        expect(lines).to.equal({ "" })
    end)

    it("error on nil", function()
        local s = nil
        expect(function() util.splitLines(s) end).to.fail()
    end)
end)
