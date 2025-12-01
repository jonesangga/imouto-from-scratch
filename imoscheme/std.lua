local eval = require("eval")
local inspect = require("libraries/inspect")
local types = require("types")
local List, is_list, is_symbol = types.List, types.is_list, types.is_symbol

local function init_lambda(params, args, evalenv, saveenv)
    local key, val
    while params.head ~= nil and args.head ~= nil do
        key = params.head
        val = args.head
        if not is_symbol(key) then
            error(key .. " is not a symbol")
        end
        saveenv:define(key.name, eval(val, evalenv))
        params, args = params.tail, args.tail
    end
    return saveenv
end


local procedures = {}

procedures["define"] = function(args, env)
    local key = args.head
    local val

    if is_list(key) then
        local L = List.from{key.tail, args.tail.head}
        val = procedures.lambda(L, env)  -- Call manually.
        key = key.head
    elseif is_symbol(key) then
        val = eval(args.tail.head, env)
    else
        error(key .. " is invalid")
    end

    env:define(key.name, val)
end

local function eval_body(list, env)
    local result
    while list.head ~= nil do
        result = eval(list.head, env)
        list = list.tail
    end
    return result
end

procedures["lambda"] = function(args, env)
    local params = args.head
    local body = args.tail

    return function(callargs, callenv)
        local localenv = env:branch()
        init_lambda(params, callargs, callenv, localenv)

        return eval_body(body, localenv)
    end
end

-- 6.1 Equivalence predicates.

-- Fix these later.
procedures["eq?"] = function(args, env)
    local x = eval(args.head, env)
    local y = eval(args.tail.head, env)
    return x == y
end

procedures["eqv?"] = procedures["eq?"]
procedures["equal?"] = procedures["eq?"]

-- 6.2 Numbers.

procedures["+"] = function(args, env)
    local res = 0
    while args.head ~= nil do
        res  = res + eval(args.head, env)
        args = args.tail
    end
    return res
end

procedures["*"] = function(args, env)
    local res = 1
    while args.head ~= nil do
        res  = res * eval(args.head, env)
        args = args.tail
    end
    return res
end

procedures["-"] = function(args, env)
    if args.head == nil then
        error("operator - needs at least one argument")
    end
    local res = eval(args.head, env)
    args = args.tail

    if args.head == nil then
        return -res
    end
    repeat
        res  = res - eval(args.head, env)
        args = args.tail
    until args.head == nil
    return res
end

-- 6.3 Other data types.

procedures["not"] = function(args, env)
    return not eval(args.head, env)
end

procedures["boolean?"] = function(args, env)
    return type(eval(args.head, env)) == "boolean"
end

procedures["string?"] = function(args, env)
    return type(eval(args.head, env)) == "string"
end

procedures["string-length"] = function(args, env)
    return #eval(args.head, env)
end

procedures["string=?"] = function(args, env)
    local x = eval(args.head, env)
    local y = eval(args.tail.head, env)
    if type(x) ~= "string" or type(y) ~= "string" then
        error("arguements must be strings")
    end
    return x == y
end

procedures["substring"] = function(args, env)
    local str = eval(args.head, env)
    local start = eval(args.tail.head, env)
    local stop = eval(args.tail.tail.head, env)
    if type(str) ~= "string" or type(start) ~= "number" or type(stop) ~= "number" then
        error("<substring> arguements not valid")
    end
    if start < 0 or stop > #str then
        error("<substring> out of range")
    end
    return str:sub(start + 1, stop)
end

procedures["string-append"] = function(args, env)
    local res = ""
    local next
    while args.head ~= nil do
        next = eval(args.head, env)
        if type(next) ~= "string" then
            error("<string-append> args must be strings")
        end
        res  = res .. next
        args = args.tail
    end
    return res
end

-- 6.6 Input and Output.

local function repr(x)
    if x == true then
        return "#t"
    elseif x == false then
        return "#f"
    else
        return x
    end
end

-- NOTE: Doesn't support port argument.
procedures["display"] = function(args, env)
    local obj = eval(args.head, env)
    if obj == nil then
        error("<display> must have one argument")
    end
    io.write(repr(obj))
end

-- NOTE: Doesn't support port argument.
procedures["newline"] = function(args, env)
    local obj = eval(args.head, env)
    if obj ~= nil then
        error("<newline> must not have argument")
    end
    io.write("\n")
end


return procedures
