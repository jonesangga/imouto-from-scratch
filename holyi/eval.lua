local types = require("types")
local inspect = require("libraries/inspect")

local TT, NT, IT = types.TT, types.NT, types.IT
local Int, Bool, String, Null, Unit = types.Int, types.Bool, types.String, types.Null, types.Unit

function eval_stmt(node, env)
    local tag = node.tag

    if tag == NT.SHOW then
        local value = eval_expr(node.expr, env)
        print(value.val)

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
        local val = node.expr and eval_expr(node.expr, env) or Null()
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

        return Null()
    end

    return { arity = arity, impl = impl }
end

function eval_expr(node, env)
    local tag = node.tag

    if tag == NT.INT then
        return Int(node.val)

    elseif tag == NT.BOOL then
        return Bool(node.val)

    elseif tag == NT.STRING then
        return String(node.val)

    elseif tag == NT.UNIT then
        return Unit()

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
        env:set(node.name, Int(result))

    elseif tag == NT.UNARY then
        local r = eval_expr(node.expr, env).val
        if node.op == TT.MINUS then
            return Int(-r)
        elseif node.op == TT.NOT then
            return Bool(not r)
        end

    elseif tag == NT.BINARY then
        local l = eval_expr(node.left, env)
        local r = eval_expr(node.right, env)
        local op = node.op

        if     op == TT.PLUS       then return Int(l.val + r.val)
        elseif op == TT.MINUS      then return Int(l.val - r.val)
        elseif op == TT.STAR       then return Int(l.val * r.val)
        elseif op == TT.SLASH      then return Int(math.floor(l.val / r.val))
        -- elseif op == "%"           then return Int(l % r)
        elseif op == TT.EQ_EQ      then return Bool(l.type == r.type and l.val == r.val)
        elseif op == TT.NOT_EQ     then return Bool(l.type == r.type and l.val ~= r.val)
        elseif op == TT.LESS       then return Bool(l.val < r.val)
        elseif op == TT.GREATER    then return Bool(l.val > r.val)
        elseif op == TT.LESS_EQ    then return Bool(l.val <= r.val)
        elseif op == TT.GREATER_EQ then return Bool(l.val >= r.val)
        elseif op == TT.AMP2       then return Bool(l.val and r.val)
        elseif op == TT.PIPE2      then return Bool(l.val or r.val)
        elseif op == TT.DOT2       then return String(l.val .. r.val)
        end

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
