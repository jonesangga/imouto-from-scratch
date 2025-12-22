local types = require("types")

local TT, NT, IT = types.TT, types.NT, types.IT

local function Int(n)    return { type = IT.INT,    val = n } end
local function Bool(b)   return { type = IT.BOOL,   val = not not b } end
local function String(s) return { type = IT.STRING, val = s} end

function eval_stmt(stmt, env)
    local tag = stmt.tag

    if tag == NT.PRINTLN then
        local value = eval_expr(stmt.expr, env)
        print(value.val)

    elseif tag == NT.EXPR_STMT then
        eval_expr(stmt.expr, env)

    elseif tag == NT.BLOCK then
        local localenv = env:branch()
        for _, s in ipairs(stmt.stmts) do
            eval_stmt(s, localenv)
        end

    elseif tag == NT.VARDECL then
        local init = eval_expr(stmt.init)
        env:define(stmt.name, init)
    end
end

function eval_expr(expr, env)
    local tag = expr.tag

    if tag == NT.INT then
        return Int(expr.val)

    elseif tag == NT.BOOL then
        return Bool(expr.val)

    elseif tag == NT.STRING then
        return String(expr.val)

    elseif tag == NT.GROUP then
        return eval_expr(expr.expr)

    elseif tag == NT.VAR then
        return env:get(expr.name)

    elseif tag == NT.ASSIGN then
        local value = eval_expr(expr.value)
        env:set(expr.name, value)
        return value

    elseif tag == NT.UNARY then
        local r = eval_expr(expr.expr, env)
        if expr.op == TT.MINUS then
            return Int(-r)
        elseif expr.op == TT.NOT then
            return Bool(not (r.tag == NT.BOOL and r.val) and r.tag ~= IT.INT or not r.val)
        end

    elseif tag == NT.BINARY then
        local l = eval_expr(expr.left, env).val
        local r = eval_expr(expr.right, env).val
        local op = expr.op

        if     op == TT.PLUS       then return Int(l + r)
        elseif op == TT.MINUS      then return Int(l - r)
        elseif op == TT.STAR       then return Int(l * r)
        elseif op == TT.SLASH      then return Int(math.floor(l / r))
        -- elseif op == "%"           then return Int(l % r)
        elseif op == TT.EQ_EQ      then return Bool(l == r)
        elseif op == TT.NOT_EQ     then return Bool(l ~= r)
        elseif op == TT.LESS       then return Bool(l < r)
        elseif op == TT.GREATER    then return Bool(l > r)
        elseif op == TT.LESS_EQ    then return Bool(l <= r)
        elseif op == TT.GREATER_EQ then return Bool(l >= r)
        -- elseif op == "&&"          then return Bool((l.tag == NT.BOOL and l.val) and (r.tag == NT.BOOL and r.val))
        -- elseif op == "||"          then return Bool((l.tag == NT.BOOL and l.val) or (r.tag == NT.BOOL and r.val))
        end
    end
end

local function eval(stmts, env)
    for _, stmt in ipairs(stmts) do
        eval_stmt(stmt, env)
    end
end

return eval
