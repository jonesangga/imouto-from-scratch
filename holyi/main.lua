local lexer  = require("lexer")
local parser = require("parser")
local eval   = require("eval")
local inspect = require("libraries/inspect")

-- local s = "print 1 + 2;"

-- local t = lexer(s)
-- print(inspect(t))

-- -- local p = parser.new(t)
-- local ast = parser(t)

-- print(inspect(ast))

-- local r = eval(ast, {})
-- print(inspect(r))

local function run_file(path, env)
    local file   = assert(io.open(path, "r"), "failed to open file")
    local tokens = lexer(file:read("*all"))
    local ast  = parser(tokens)
    file:close()

    local result = eval(ast, env)
end

do
    if #arg == 0 then
        print("Usage: lua main.lua <file>")
    else
        run_file(arg[1], {})
    end
end
