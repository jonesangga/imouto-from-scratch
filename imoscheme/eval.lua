local types = require("types")

local is_pair   = types.is_pair
local is_quote  = types.is_quote
local is_symbol = types.is_symbol

-- TODO: Using is_pair() is not correct but using is_list() is costly. Think again.
local function eval(expr, env)
    if is_symbol(expr) then
        return env:get(expr.name)

    elseif is_quote(expr) then
        return expr.value

    elseif is_pair(expr) then
        local fn   = eval(expr.car, env)
        local args = expr.cdr
        return fn(args, env)

    else
        -- String, number, true, false.
        return expr
    end
end

return eval
