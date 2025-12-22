local lexer  = require("lexer")
local parser = require("parser")
local eval   = require("eval")
local envir  = require("envir")
local std    = require("std")
local typecheck = require("typecheck")
local inspect = require("libraries/inspect")

-- local s = "print 1 + 2;"

-- local t = lexer(s)
-- print(inspect(t))

-- -- local p = parser.new(t)
-- local ast = parser(t)

-- print(inspect(ast))

-- local r = eval(ast, {})
-- print(inspect(r))

local function run_file(path, env, tenv)
    local file   = assert(io.open(path, "r"), "failed to open file")
    local tokens = lexer(file:read("*all"))
    file:close()

    local ast  = parser(tokens)
    typecheck(ast, tenv)

    local result = eval(ast, env)
end

do
    local env, tenv = {}, {}

    for name, data in pairs(std.procedures) do
        env[name]  = { arity = data.arity, impl = data.impl }
        tenv[name] = data.sig
    end

    env, tenv = envir.new(env), envir.new(tenv)

    if #arg == 0 then
        print("Usage: lua main.lua <file>")
    else
        run_file(arg[1], env, tenv)
    end
end
