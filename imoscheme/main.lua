local tokenize = require("tokenize")
local parse    = require("parse")
local eval     = require("eval")
local envir    = require("envir")
local std      = require("std")
local inspect  = require("libraries/inspect")

local function run_file(path, env)
    local file   = assert(io.open(path, "r"), "failed to open file")
    local tokens = tokenize(file:read("*all"))
    local exprs  = parse(tokens)
    file:close()

    local result
    for _, expr in ipairs(exprs) do
        result = eval(expr, env)
    end
end

local function repr(x)
    if x == nil then
        return
    elseif x == true then
        print("#t")
    elseif x == false then
        print("#f")
    else
        print(x)
    end
end

local function repl(env)
    print("Imo Scheme. Ctrl+D to quit.")

    local tokens, exprs, result

    while true do
        io.write("> ")
        tokens = tokenize(io.read())
        exprs = parse(tokens)
        -- print(inspect(exprs))

        for _, expr in ipairs(exprs) do
            result = eval(expr, env)
        end
        repr(result)
    end
end

do
    local env = envir.new(std)

    if #arg == 0 then
        repl(env)
    else
        run_file(arg[1], env)
    end
end
