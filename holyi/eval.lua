local types = require("types")

local TT, NT, IT = types.TT, types.NT, types.IT

local function Int(n)    return { type = IT.INT,    val = n } end
local function Bool(b)   return { type = IT.BOOL,   val = not not b } end
local function String(s) return { type = IT.STRING, val = s} end

local function check_number(v)
    if v.type ~=  IT.INT then
        error("expected number, got " .. v.type)
    end
    return v.val
end

function eval_stmt(stmt, env)
    local type = stmt.type

    if type == NT.PRINTLN then
        local value = eval_expr(stmt.value, env)
        print(value.val)

    elseif type == NT.EXPR_STMT then
        eval_expr(stmt.expr, env)

    else
        error("unsupported stmt " .. tag)
    end
end

function eval_expr(expr, env)
    local type = expr.type

    if type == NT.INT then
        return Int(expr.val)

    elseif type == NT.BOOL then
        return Bool(expr.val)

    elseif type == NT.STRING then
        return String(expr.val)

    elseif type == NT.UNARY then
        local r = eval_expr(expr.expr, env)
        if expr.op == TT.MINUS then
            return Int(-check_number(r))
        elseif expr.op == TT.NOT then
            return Bool(not (r.type == NT.BOOL and r.val) and r.type ~= IT.INT or not r.val)
        end

    elseif type == NT.BINARY then
        local l = eval_expr(expr.left, env)
        local r = eval_expr(expr.right, env)
        local op = expr.op

        if     op == TT.PLUS       then return Int(check_number(l) + check_number(r))
        elseif op == TT.MINUS      then return Int(check_number(l) - check_number(r))
        elseif op == TT.STAR       then return Int(check_number(l) * check_number(r))
        elseif op == TT.SLASH      then return Int(math.floor(check_number(l) / check_number(r)))
        elseif op == "%"           then return Int(check_number(l) % check_number(r))
        elseif op == TT.EQ_EQ      then return Bool((l.type == r.type) and (l.val == r.val))
        elseif op == TT.NOT_EQ     then return Bool(not ((l.type == r.type) and (l.val == r.val)))
        elseif op == TT.LESS       then return Bool(check_number(l) < check_number(r))
        elseif op == TT.GREATER    then return Bool(check_number(l) > check_number(r))
        elseif op == TT.LESS_EQ    then return Bool(check_number(l) <= check_number(r))
        elseif op == TT.GREATER_EQ then return Bool(check_number(l) >= check_number(r))
        elseif op == "&&"          then return Bool((l.type == NT.BOOL and l.val) and (r.type == NT.BOOL and r.val))
        elseif op == "||"          then return Bool((l.type == NT.BOOL and l.val) or (r.type == NT.BOOL and r.val))
        else error("Unknown binary op " .. expr.op)
        end
    else
        error("Eval: unsupported expr " .. tostring(type))
    end
end

local function eval(stmts)
    for _, stmt in ipairs(stmts) do
        eval_stmt(stmt)
    end
end

return eval
