local RuntimeError = require("error").RuntimeError
local types = require("types")
local inspect = require("libraries/inspect")

local TT, NT, IT = types.TT, types.NT, types.IT
local Int, Bool, String, unit, Array = types.Int, types.Bool, types.String, types.unit, types.Array

function eval_stmt(node, env)
    local tag = node.tag

    if tag == NT.SHOW then
        local value = eval_expr(node.expr, env)
        print(value)

    elseif tag == NT.IF then
        local cond = eval_expr(node.cond, env)
        if cond.val then
            eval_stmt(node.then_, env)
        elseif node.else_ then
            eval_stmt(node.else_, env)
        end

    elseif tag == NT.EXPR_STMT then
        eval_expr(node.expr, env)

    elseif tag == NT.WHILE then
        while eval_expr(node.cond, env).val do
            eval_stmt(node.body, env)
        end

    elseif tag == NT.BLOCK then
        local localenv = env:branch()
        for _, s in ipairs(node.stmts) do
            eval_stmt(s, localenv)
        end

    elseif tag == NT.VARDECL then
        local init = eval_expr(node.init, env)
        env:define(node.name, init)

    elseif tag == NT.FUNDECL then
        local fn = Function(node)
        env:define(node.name, fn)

    elseif tag == NT.RETURN then
        local val = node.expr and eval_expr(node.expr, env) or unit
        error({_return = val})
    end
end

-- TODO: Fix return value in impl.
function Function(node)
    local arity = #node.params
    local impl = function(args, env)
        local localenv = env:branch()
        for i = 1, #node.params do
            localenv:define(node.params[i].name, args[i])
        end

        local ok, ret = pcall(function()
            for _, s in ipairs(node.body) do
                eval_stmt(s, localenv)
            end
        end)

        if not ok then
            -- Check for return signal.
            if type(ret) == "table" and ret._return ~= nil then
                return ret._return
            end
            error(ret)
        end

        return unit
    end

    return { arity = arity, impl = impl }
end

function eval_expr(node, env)
    local tag = node.tag

    if tag == NT.INT then
        return Int.new(node.val)

    elseif tag == NT.BOOL then
        return Bool.new(node.val)

    elseif tag == NT.STRING then
        return String.new(node.val)

    elseif tag == NT.ARRAY then
        local t = {}
        for _, el in ipairs(node.array) do
            table.insert(t, eval_expr(el))
        end
        return Array.new(t)

    elseif tag == NT.UNIT then
        return unit

    elseif tag == NT.GROUP then
        return eval_expr(node.expr, env)

    elseif tag == NT.VAR then
        return env:get(node.name)

    elseif tag == NT.ASSIGN then
        local rhs = eval_expr(node.value, env)
        local op = node.op
        if op == TT.EQ then
            env:set(node.name, rhs)
            return rhs
        end

        local lhs = env:get(node.name)
        local result
        if     op == TT.PLUS_EQ  then result = lhs.val + rhs.val
        elseif op == TT.MINUS_EQ then result = lhs.val - rhs.val
        elseif op == TT.STAR_EQ  then result = lhs.val * rhs.val
        elseif op == TT.SLASH_EQ then result = math.floor(lhs.val / rhs.val)
        end
        env:set(node.name, Int.new(result))

    elseif tag == NT.UNARY then
        local r = eval_expr(node.right, env).val
        if node.op == TT.MINUS then
            return Int.new(-r)
        elseif node.op == TT.NOT then
            return Bool.new(not r)
        elseif node.op == TT.HASH then
            return #r
        end

    elseif tag == NT.BINARY then
        local l = eval_expr(node.left, env)
        local r = eval_expr(node.right, env)
        local op = node.op

        if     op == TT.PLUS       then return Int.new(l.val + r.val)
        elseif op == TT.MINUS      then return Int.new(l.val - r.val)
        elseif op == TT.STAR       then return Int.new(l.val * r.val)
        elseif op == TT.SLASH      then return Int.new(math.floor(l.val / r.val))
        -- elseif op == "%"           then return Int(l % r)
        elseif op == TT.EQ_EQ      then return Bool.new(l.type == r.type and l.val == r.val)
        elseif op == TT.NOT_EQ     then return Bool.new(l.type == r.type and l.val ~= r.val)
        elseif op == TT.LESS       then return Bool.new(l.val < r.val)
        elseif op == TT.GREATER    then return Bool.new(l.val > r.val)
        elseif op == TT.LESS_EQ    then return Bool.new(l.val <= r.val)
        elseif op == TT.GREATER_EQ then return Bool.new(l.val >= r.val)
        elseif op == TT.AMP2       then return Bool.new(l.val and r.val)
        elseif op == TT.PIPE2      then return Bool.new(l.val or r.val)
        elseif op == TT.DOT2       then return String.new(l.val .. r.val)
        end

    elseif tag == NT.INDEX then
        local array = eval_expr(node.base, env).val
        local index = eval_expr(node.index, env).val
        if index > #array then
            RuntimeError("out of bound index")
        end
        return array[index]

    elseif tag == NT.CALL then
        local callee = eval_expr(node.callee, env)

        local args = {}
        for _, arg in ipairs(node.args) do
            table.insert(args, eval_expr(arg, env))
        end

        return callee.impl(args, env)
    end
end

local function eval(stmts, env)
    for _, stmt in ipairs(stmts) do
        eval_stmt(stmt, env)
    end
end

return eval
