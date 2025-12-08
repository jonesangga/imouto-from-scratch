local cwd  = (...):gsub('%.?std$', '') .. "."

local eval  = require(cwd .. "eval")
local state = require(cwd .. "state")
local types = require(cwd .. "types")

local EMPTY     = types.EMPTY
local list      = types.list
local port      = types.port
local is_char   = types.is_char
local is_empty  = types.is_empty
local is_list   = types.is_list
local is_pair   = types.is_pair
local is_symbol = types.is_symbol

local function compare_using(fn)
    return function(args, env)
        if is_empty(args) then
            return true
        end

        local prev, current
        prev = eval(args.car, env)
        args = args.cdr

        while not is_empty(args) do
            current = eval(args.car, env)
            if not fn(prev, current) then
                return false
            end
            prev = current
            args = args.cdr
        end
        return true
    end
end

local function init_lambda(params, args, evalenv, saveenv)
    local key, val
    while params.car ~= nil and args.car ~= nil do
        key = params.car
        val = args.car
        if not is_symbol(key) then
            error(key .. " is not a symbol")
        end
        saveenv:define(key.name, eval(val, evalenv))
        params, args = params.cdr, args.cdr
    end
    return saveenv
end

local function init_let(bindings, evalenv, saveenv)
    local key, val
    while not is_empty(bindings) do
        key = bindings.car.car
        val = bindings.car.cdr.car
        if not is_symbol(key) then
            error(key .. " is not a symbol")
        end
        saveenv:define(key.name, eval(val, evalenv))
        bindings = bindings.cdr
    end
    return saveenv
end


local procedures = {}

procedures["define"] = function(args, env)
    local key = args.car
    local val

    if is_pair(key) then
        local L = list {key.cdr, args.cdr.car}
        val = procedures.lambda(L, env)  -- Call manually.
        key = key.car
    elseif is_symbol(key) then
        val = eval(args.cdr.car, env)
    else
        error(key .. " is invalid")
    end

    env:define(key.name, val)
end

local function eval_body(expr, env)
    local result
    while not is_empty(expr) do
        result = eval(expr.car, env)
        expr = expr.cdr
    end
    return result
end

procedures["lambda"] = function(args, env)
    local params = args.car
    local body = args.cdr

    return function(callargs, callenv)
        local localenv = env:branch()
        init_lambda(params, callargs, callenv, localenv)

        return eval_body(body, localenv)
    end
end

procedures["if"] = function(args, env)
    local iftrue = args.cdr.car
    local iffalse = args.cdr.cdr.car
    if eval(args.car, env) then
        return eval(iftrue, env)
    else
        return eval(iffalse, env)
    end
end

procedures["set!"] = function(args, env)
    local key = args.car
    if not is_symbol(key) then
        error(key .. " is not a symbol")
    end
    local val = eval(args.cdr.car, env)
    env:set(key.name, val)
end

procedures["cond"] = function(args, env)
    local condition, body
    while args.car ~= nil do
        condition = args.car.car
        body = args.car.cdr
        if eval(condition, env) then
            if body.car ~= nil then
                return eval_body(body, env)
            else
                return true
            end
        end
        args = args.cdr
    end
end

procedures["else"] = true

procedures["let"] = function(args, env)
    local bindings = args.car
    local body = args.cdr

    local localenv = env:branch()
    init_let(bindings, env, localenv)

    return eval_body(body, localenv)
end

procedures["let*"] = function(args, env)
    local bindings = args.car
    local body = args.cdr

    local localenv = env:branch()
    init_let(bindings, localenv, localenv)

    return eval_body(body, localenv)
end

procedures["begin"] = function(args, env)
    return eval_body(args, env)
end

-- 6.1 Equivalence predicates.

-- Fix these later.
procedures["eq?"] = function(args, env)
    local x = eval(args.car, env)
    local y = eval(args.cdr.car, env)
    return x == y
end

procedures["eqv?"] = procedures["eq?"]
procedures["equal?"] = procedures["eq?"]

-- 6.2 Numbers.

procedures["="] = compare_using(function(x, y) return x == y end)

procedures["<"] = compare_using(function(x, y) return x < y end)

procedures[">"] = compare_using(function(x, y) return x > y end)

procedures["<="] = compare_using(function(x, y) return x <= y end)

procedures[">="] = compare_using(function(x, y) return x >= y end)

procedures["+"] = function(args, env)
    local res = 0
    while not is_empty(args) do
        res  = res + eval(args.car, env)
        args = args.cdr
    end
    return res
end

procedures["*"] = function(args, env)
    local res = 1
    while not is_empty(args) do
        res  = res * eval(args.car, env)
        args = args.cdr
    end
    return res
end

procedures["-"] = function(args, env)
    if is_empty(args) then
        error("operator - needs at least one argument")
    end
    local res = eval(args.car, env)
    args = args.cdr

    if is_empty(args) then
        return -res
    end
    repeat
        res  = res - eval(args.car, env)
        args = args.cdr
    until args.car == nil
    return res
end

-- 6.3 Other data types.

procedures["not"] = function(args, env)
    return not eval(args.car, env)
end

procedures["boolean?"] = function(args, env)
    return type(eval(args.car, env)) == "boolean"
end

local function eval_to_list(expr, env)
    local arr = {}
    while not is_empty(expr) do
        table.insert(arr, eval(expr.car, env))
        expr = expr.cdr
    end
    return list(arr)
end

procedures["list?"] = function(args, env)
    return is_list(eval(args.car, env))
end

procedures["list"] = function(args, env)
    return eval_to_list(args, env)
end

procedures["length"] = function(args, env)
    local list = eval(args.car, env)
    local len = 0
    while not is_empty(list) do
        len = len + 1
        list = list.cdr
    end
    return len
end

procedures["string?"] = function(args, env)
    return type(eval(args.car, env)) == "string"
end

procedures["string-length"] = function(args, env)
    return #eval(args.car, env)
end

procedures["string=?"] = function(args, env)
    local x = eval(args.car, env)
    local y = eval(args.cdr.car, env)
    if type(x) ~= "string" or type(y) ~= "string" then
        error("arguements must be strings")
    end
    return x == y
end

procedures["substring"] = function(args, env)
    local str = eval(args.car, env)
    local start = eval(args.cdr.car, env)
    local stop = eval(args.cdr.cdr.car, env)
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
    while not is_empty(args) do
        next = eval(args.car, env)
        if type(next) ~= "string" then
            error("<string-append> args must be strings")
        end
        res  = res .. next
        args = args.cdr
    end
    return res
end

procedures["string-copy"] = function(args, env)
    local s = eval(args.car, env)
    if type(s) ~= "string" then
        error("<string-copy> arg must be a string")
    end
    return s
end

-- 6.6 Input and Output.

procedures["open-input-file"] = function(args, env)
    local path = eval(args.car, env)
    if type(path) ~= "string" then
        error("<open-input-file> arg must be string")
    end

    path = state.resolve(path)
    local fp, err = io.open(path, "r")
    if not fp then
        error("<open-input-file> failed to open " .. path)
    end

    return port("input port", fp, path)
end

procedures["read-char"] = function(args, env)
    local port = eval(args.car, env)
    return port:read_char()
end

local function display(x)
    if x == true then
        return "#t"
    elseif x == false then
        return "#f"
    elseif is_char(x) then
        return x:display()
    else
        return tostring(x)
    end
end

-- NOTE: Doesn't support port argument.
procedures["display"] = function(args, env)
    local obj = eval(args.car, env)
    io.write(display(obj))
end

-- NOTE: Doesn't support port argument.
procedures["newline"] = function(args, env)
    local obj = eval(args.car, env)
    if obj ~= nil then
        error("<newline> must not have argument")
    end
    io.write("\n")
end


return procedures
