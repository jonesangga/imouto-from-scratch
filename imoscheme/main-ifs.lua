local cwd = "imoscheme."

local tokenize = require(cwd .. "tokenize")
local parse    = require(cwd .. "parse")
local eval     = require(cwd .. "eval")
local envir    = require(cwd .. "envir")
local std      = require(cwd .. "std")
local racket   = require(cwd .. "racket")
local state    = require(cwd .. "state")

local imoscm = {}

local env = envir.new(std)
env:add_module(racket)

function imoscm.run_file(path)
    local file   = assert(io.open(path, "r"), "failed to open file")
    state.push_base(path)
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

    state.push_base(".")
    local line, tokens, exprs, result

    while true do
        io.write("> ")
        line = io.read()
        if not line then break end

        tokens = tokenize(line)
        exprs = parse(tokens)

        for _, expr in ipairs(exprs) do
            result = eval(expr, env)
        end
        repr(result)
    end
end

return imoscm
