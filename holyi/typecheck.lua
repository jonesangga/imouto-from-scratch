local types = require("types")

local TT, NT, IT = types.TT, types.NT, types.IT

local function assert_eq(a, b, msg)
    if a.tag ~= b.tag then
        error(msg or "type not match")
    end
end

local function check_expr(node, tenv)
    local t = node.tag

    if t == NT.INT or t == NT.BOOL or t == NT.STRING then
        return node.type

    elseif t == NT.BINARY then
        local lt = check_expr(node.left, tenv)
        local rt = check_expr(node.right, tenv)
        local op = node.op

        if op == TT.PLUS or op == TT.MINUS then
            assert_eq(lt, rt, "arithmetics on non-int")
            return node.left.type  -- TODO: Think again.
        else
            error("Unknown binop " .. op)
        end
    else
        error("Expr type not implemented: " .. tostring(t))
    end
end

local function check_stmt(node, tenv, ret_ty)
    local t = node.tag

    if t == NT.PRINTLN then
        check_expr(node.expr, tenv)
    elseif t == NT.EXPR_STMT then
        check_expr(node.expr, tenv)
    else
        error("Stmt typecheck not implemented: " .. t)
    end
end

local function typecheck(ast)
    for _, stmt in ipairs(ast) do
        check_stmt(stmt, {}, nil)
    end

    return global
end

return typecheck
