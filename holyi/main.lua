-- Make it error to access undeclared variable.
-- TODO: Make a check. Do this only if not used as module.
do
    local declared = {}  -- To handle assignment with nil.
    setmetatable(_G, {
        __newindex = function(t, k, v)
            declared[k] = true
            rawset(t, k, v)
        end,

        __index = function(t, k)
            if not declared[k] then
                error("undeclared variable '" .. k .. "'", 2)
            end
        end,
    })
end

local lexer     = require("lexer")
local parser    = require("parser")
local typecheck = require("typecheck")
local eval      = require("eval")
local envir     = require("envir")
local std       = require("std")

local function run_file(path, env, tenv)
    local file = io.open(path, "r")
    if not file then
        error("failed to open file: " .. path)
    end

    local src = file:read("*all")
    file:close()

    local ok, lexer_result = pcall(lexer, src)
    if not ok then
        print(lexer_result)
        return;
    end

    local ok, parser_result = pcall(parser, lexer_result)
    if not ok then
        print(parser_result)
        return;
    end

    local ok, err = pcall(typecheck, parser_result, tenv)
    if not ok then
        print(err)
        return;
    end

    eval(parser_result, env)
end

do
    local env, tenv = {}, {}

    for name, proc in pairs(std.procedures) do
        env[name]  = proc.data
        tenv[name] = proc.type
    end

    env, tenv = envir.new(env), envir.new(tenv)

    if #arg == 0 then
        print("Usage: lua main.lua <file>")
    else
        run_file(arg[1], env, tenv)
    end
end
