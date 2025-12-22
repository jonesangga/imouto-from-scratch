local types = require("types")
local envir = require("envir")

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

    elseif t == NT.VAR then
        return tenv:get(node.name)

    elseif t == NT.ASSIGN then
        local type = tenv:get(node.name)
        local et = check_expr(node.value)
        assert_eq(type, et)
        return type

    elseif t == NT.GROUP then
        return check_expr(node.expr, tenv)

    elseif t == NT.BINARY then
        local lt = check_expr(node.left, tenv)
        local rt = check_expr(node.right, tenv)
        local op = node.op

        if op == TT.PLUS or op == TT.MINUS or op == TT.STAR or op == TT.SLASH then
            assert_eq(lt, IT.Int)
            assert_eq(rt, IT.Int)
            return IT.Int
        elseif op == TT.EQ_EQ or op == TT.NOT_EQ then
            assert_eq(lt, rt)
            return IT.Bool
        elseif op == TT.LESS or op == TT.LESS_EQ or op == TT.GREATER or op == TT.GREATER_EQ then
            -- TODO: Support comparing string.
            assert_eq(lt, IT.Int)
            assert_eq(rt, IT.Int)
            return IT.Bool
        elseif op == TT.AMP2 or op == TT.PIPE2 then
            assert_eq(lt, IT.Bool)
            assert_eq(rt, IT.Bool)
            return IT.Bool
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

    elseif t == NT.IF then
        local ct = check_expr(node.cond, tenv)
        assert_eq(ct, IT.Bool, "if condition not bool")

        check_stmt(node.then_, tenv, ret_ty)
        if node.else_ then
            check_stmt(node.else_, tenv, ret_ty)
        end

    elseif t == NT.EXPR_STMT then
        check_expr(node.expr, tenv)

    elseif t == NT.BLOCK then
        local localenv = tenv:branch()
        for _, s in ipairs(node.stmts) do
            check_stmt(s, localenv, ret_ty)
        end

    elseif t == NT.VARDECL then
        local vartype = IT[node.vartype]
        local et = check_expr(node.init, tenv)
        assert_eq(vartype, et)
        tenv:define(node.name, et)
    else
        error("Stmt typecheck not implemented: " .. t)
    end
end

local function typecheck(ast)
    local tenv = envir:new({})

    for _, stmt in ipairs(ast) do
        check_stmt(stmt, tenv, nil)
    end

    return tenv
end

return typecheck
