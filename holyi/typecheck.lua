local inspect = require("libraries/inspect")
local types = require("types")

local TT, NT, IT = types.TT, types.NT, types.IT
local InternalTags = types.InternalTags
local assert_eq = types.assert_eq
local FnType = types.FnType

local function check_expr(node, tenv)
    local t = node.tag

    if t == NT.INT or t == NT.BOOL or t == NT.STRING then
        return node.type

    elseif t == NT.VAR then
        return tenv:get(node.name)

    elseif t == NT.ASSIGN then
        local type = tenv:get(node.name)
        local et = check_expr(node.value, tenv)
        assert_eq(type, et)
        return type

    elseif t == NT.GROUP then
        return check_expr(node.expr, tenv)

    elseif t == NT.CALL then
        local fty = check_expr(node.callee, tenv)
        if not fty then
            error("call of undefined function")
        end
        if fty.tag ~= InternalTags.FN then
            error("trying to call non-function")
        end
        if #node.args ~= #fty.params then
            error("arg count mismatch")
        end
        for i = 1, #node.args do
            local at = check_expr(node.args[i], tenv)
            assert_eq(at, fty.params[i], "arg " .. i .. " type mismatch")
        end
        return fty.ret

    elseif t == NT.BINARY then
        local lt = check_expr(node.left, tenv)
        local rt = check_expr(node.right, tenv)
        local op = node.op

        if op == TT.PLUS or op == TT.MINUS or op == TT.STAR or op == TT.SLASH then
            assert_eq(lt, IT.Int)
            assert_eq(rt, IT.Int)
            return lt
        elseif op == TT.EQ_EQ or op == TT.NOT_EQ then
            assert_eq(lt, rt)  -- TODO: Do it have to be the same type?
            return IT.Bool
        elseif op == TT.LESS or op == TT.LESS_EQ or op == TT.GREATER or op == TT.GREATER_EQ then
            -- TODO: Support comparing string.
            assert_eq(lt, IT.Int)
            assert_eq(rt, IT.Int)
            return IT.Bool
        elseif op == TT.AMP2 or op == TT.PIPE2 then
            assert_eq(lt, IT.Bool)
            assert_eq(rt, IT.Bool)
            return lt
        elseif op == TT.DOT2 then
            assert_eq(lt, IT.String)
            assert_eq(rt, IT.String)
            return lt
        else
            error("unknown binop " .. op)
        end
    else
        error("expr type not implemented: " .. tostring(t))
    end
end

local function check_stmt(node, tenv, ret_ty)
    local t = node.tag

    if t == NT.SHOW then
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

    elseif t == NT.WHILE then
        local ct = check_expr(node.cond, tenv)
        assert_eq(ct, IT.Bool, "while condition not bool")
        check_stmt(node.body, tenv, ret_ty)

    elseif t == NT.BLOCK then
        local localenv = tenv:branch()
        for _, s in ipairs(node.stmts) do
            check_stmt(s, localenv, ret_ty)
        end

    -- TODO: Support non builtins type.
    elseif t == NT.VARDECL then
        local vartype = IT[node.vartype]
        local et = check_expr(node.init, tenv)
        assert_eq(vartype, et)
        tenv:define(node.name, et)

    elseif t == NT.RETURN then
        local et = node.expr and check_expr(node.expr, tenv) or IT.Void
        if ret_ty == nil then
            error("return outside function")
        end
        assert_eq(et, ret_ty)

    else
        error("stmt typecheck not implemented: " .. t)
    end
end

function analyze_stmt_list(stmt_list, tenv, returns)
    for i, stmt in ipairs(stmt_list) do
        if stmt.tag == NT.RETURN then
            local et = stmt.expr and check_expr(stmt.expr, tenv) or IT.Void
            table.insert(returns, et)
            return true
        end
    end

    return false
end

-- TODO: Clean up. Rename.
local function check_function_returns(stmt, tenv)
    local fty = stmt.type
    local localenv = tenv:branch()
    for i, p in ipairs(stmt.params) do
        localenv:define(p.name, fty.params[i])
    end

    for _, s in ipairs(stmt.body) do
        check_stmt(s, localenv, fty.ret)
    end

    -- Collect returns while typechecking body.
    local returns = {}
    local always = analyze_stmt_list(stmt.body, localenv, returns)

    if not always then
        -- Either the fn must have Void type or error.
        assert_eq(fty.ret, IT.Void, "fn ret type should be Void")
    end

    for _, type in ipairs(returns) do
        assert_eq(type, fty.ret)
    end
end

local function typecheck(ast, tenv)
    -- Register function signatures.
    for _, stmt in ipairs(ast) do
        if stmt.tag == NT.FUNDECL then
            local param_types = {}
            for i = 1, #stmt.params do
                param_types[i] = IT[stmt.params[i].type]
            end
            local fty = FnType(param_types, IT[stmt.rettype])    -- TODO: Clean up.
            stmt.type = fty
            tenv:define(stmt.name, fty)
        end
    end

    -- Typecheck function bodies and annotate nodes.
    for _, stmt in ipairs(ast) do
        if stmt.tag == NT.FUNDECL then
            check_function_returns(stmt, tenv)
        else
            check_stmt(stmt, tenv, nil)
        end
    end
end

return typecheck
