-- TODO: Fix state implementation.

local tokenize = require("imoscheme.tokenize")
local parse    = require("imoscheme.parse")
local eval     = require("imoscheme.eval")
local envir    = require("imoscheme.envir")
local std      = require("imoscheme.std")
local racket   = require("imoscheme.racket")
local state    = require("imoscheme.state")

local imoscm = {}
imoscm.print = print

local env = envir.new(std.procedures)
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
        imoscm.print("#t")
    elseif x == false then
        imoscm.print("#f")
    else
        imoscm.print(x)
    end
end

function imoscm.prepare_repl()
    imoscm.print("Imo Scheme. Ctrl+D to quit.")
    state.push_base(".")
end

function imoscm.line(line)
    local tokens = tokenize(line)
    local exprs = parse(tokens)

    local result
    for _, expr in ipairs(exprs) do
        result = eval(expr, env)
    end
    repr(result)
end

function imoscm.setup(writefn, printfn)
    std.write = writefn
    imoscm.print = printfn
end

return imoscm
