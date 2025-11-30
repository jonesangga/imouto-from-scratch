local parser  = require("parser")
local eval    = require("eval")
local envir   = require("envir")
local std     = require("std")
local inspect = require("libraries/inspect")

local function run_file(path, env)
    local file  = assert(io.open(path, "r"), "failed to open file")
    local exprs = parser(file:read("*all"))
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
        print(inspect(x))
    end
end

local function repl(env)
    print("Imo Scheme. Ctrl+D to quit.")

    local exprs, result

    while true do
        io.write("> ")
        exprs = parser(io.read())
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
