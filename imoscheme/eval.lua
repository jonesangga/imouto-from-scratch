local types = require("types")
local is_list, is_symbol = types.is_list, types.is_symbol

local function eval_list(list, env)
    local fn = eval(list.head, env)
    local args = list.tail
    return fn(args, env)
end

-- NOTE: This cannot be local because this and eval_list call each other.
function eval(expr, env)
    if is_symbol(expr) then
        return env:get(expr.name)
    elseif is_list(expr) then
        return eval_list(expr, env)
    else
        return expr
    end
end

return eval
