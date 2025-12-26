local TypeCheckError = require("error").TypeCheckError
local inspect = require("libraries/inspect")
local types = require("types")

local TT, NT, primitives = types.TT, types.NT, types.primitives
local InternalTags = types.InternalTags
local assert_eq = types.assert_eq
local FnType = types.FnType
local ArrayType = types.ArrayType

function resolve(arg, param, subst)
    if param.tag == InternalTags.TYPEVAR then
        if subst[param.name] then
            assert_eq(arg, subst[param.name], "type variable mismatch")
        else
            subst[param.name] = arg
        end
    elseif param.tag == InternalTags.ARRAY then
        if arg.tag ~= InternalTags.ARRAY then
            TypeCheckError("expect array got non array")
        end
        resolve(arg.eltype, param.eltype, subst)
    end
end

local function check_expr(node, tenv)
    local t = node.tag

    if t == NT.INT or t == NT.BOOL or t == NT.STRING or t == NT.UNIT then
        return node.type

    -- Only support array of primitive type.
    -- TODO: support multidimensional array of primitive type.
    elseif t == NT.ARRAY then
        local eltype = primitives.Any
        for _, el in ipairs(node.array) do
            local t = check_expr(el, tenv)
            assert_eq(eltype, t)
            eltype = t
        end
        return ArrayType(eltype)

    elseif t == NT.VAR then
        return tenv:get(node.name)

    elseif t == NT.ASSIGN then
        local type = tenv:get(node.name)
        local et = check_expr(node.value, tenv)
        assert_eq(type, et)
        local op = node.op
        if op ~= TT.EQ then
            assert_eq(type, primitives.Int)
        end
        return type

    elseif t == NT.GROUP then
        return check_expr(node.expr, tenv)

    elseif t == NT.CALL then
        local fty = check_expr(node.callee, tenv)
        if not fty then
            error("call of undefined function")
        end

        if fty.tag == InternalTags.FN then
            if #node.args ~= #fty.params then
                error("arg count mismatch")
            end
            for i = 1, #node.args do
                local at = check_expr(node.args[i], tenv)
                assert_eq(at, fty.params[i], "arg " .. i .. " type mismatch")
            end
            return fty.ret

        elseif fty.tag == InternalTags.GENERIC_FN then
            if #node.args ~= #fty.params then
                error("arg count mismatch")
            end

            local tparams = fty.tparams
            local gparams = fty.params
            local args = node.args

            local subst = {}
            for i = 1, #gparams do
                local at = check_expr(args[i], tenv)
                resolve(at, gparams[i], subst)
            end

            if fty.ret.tag == InternalTags.TYPEVAR then
                local ret = subst[fty.ret.name]
                if not ret then
                    TypeCheckError("return type mismatch")
                end
                return ret
            else
                return fty.ret
            end

        else
            error("trying to call non-function")
        end

    elseif t == NT.BINARY then
        local lt = check_expr(node.left, tenv)
        local rt = check_expr(node.right, tenv)
        local op = node.op

        if op == TT.PLUS or op == TT.MINUS or op == TT.STAR or op == TT.SLASH then
            assert_eq(lt, primitives.Int)
            assert_eq(rt, primitives.Int)
            return lt
        elseif op == TT.EQ_EQ or op == TT.NOT_EQ then
            return primitives.Bool
        elseif op == TT.LESS or op == TT.LESS_EQ or op == TT.GREATER or op == TT.GREATER_EQ then
            -- TODO: Support comparing string.
            assert_eq(lt, primitives.Int)
            assert_eq(rt, primitives.Int)
            return primitives.Bool
        elseif op == TT.AMP2 or op == TT.PIPE2 then
            assert_eq(lt, primitives.Bool)
            assert_eq(rt, primitives.Bool)
            return lt
        elseif op == TT.DOT2 then
            assert_eq(lt, primitives.String)
            assert_eq(rt, primitives.String)
            return lt
        else
            error("unknown binop " .. op)
        end
    else
        error("expr type not implemented: " .. tostring(t))
    end
end

function resolve_type(t)
    if type(t) == "string" then
        if primitives[t] then
            return primitives[t]
        end
        TypeCheckError("unresolved type " .. t)
    elseif t.kind == "array" then
        return ArrayType(resolve_type(t.name))
    end
end

local function check_stmt(node, tenv, ret_ty)
    local t = node.tag

    if t == NT.SHOW then
        check_expr(node.expr, tenv)

    elseif t == NT.IF then
        local ct = check_expr(node.cond, tenv)
        assert_eq(ct, primitives.Bool, "if condition not bool")

        check_stmt(node.then_, tenv, ret_ty)
        if node.else_ then
            check_stmt(node.else_, tenv, ret_ty)
        end

    elseif t == NT.EXPR_STMT then
        check_expr(node.expr, tenv)

    elseif t == NT.WHILE then
        local ct = check_expr(node.cond, tenv)
        assert_eq(ct, primitives.Bool, "while condition not bool")
        check_stmt(node.body, tenv, ret_ty)

    elseif t == NT.BLOCK then
        local localenv = tenv:branch()
        for _, s in ipairs(node.stmts) do
            check_stmt(s, localenv, ret_ty)
        end

    elseif t == NT.VARDECL then
        local vartype = resolve_type(node.vartype)
        local et = check_expr(node.init, tenv)
        assert_eq(et, vartype, "vardecl mismatch")
        tenv:define(node.name, et)

    elseif t == NT.RETURN then
        local et = node.expr and check_expr(node.expr, tenv) or primitives.Unit
        if ret_ty == nil then
            error("return outside function")
        end
        assert_eq(et, ret_ty)

    else
        error("stmt typecheck not implemented: " .. t)
    end
end

-- TODO: Think how to do it by just passing a stmt, not a table.
-- TODO: How to pass specific error like in if stmt? Should it be the first fallthrough?
function analyze_stmt_list(stmt_list, tenv, returns)
    for i, stmt in ipairs(stmt_list) do
        if stmt.tag == NT.RETURN then
            local et = stmt.expr and check_expr(stmt.expr, tenv) or primitives.Unit
            table.insert(returns, et)
            return true
        end

        if stmt.tag == NT.IF then
            local ct = check_expr(stmt.cond, tenv)
            assert_eq(ct, primitives.Bool, "if condition not bool")

            local then_returns = analyze_stmt_list({stmt.then_}, tenv, returns)
            if stmt.else_ then
                else_returns = analyze_stmt_list({stmt.else_}, tenv, returns)
                if then_returns and else_returns then
                    return true
                end
            end
            -- Fallthrough.

        elseif stmt.tag == NT.BLOCK then
            local localenv = tenv:branch()
            local block_returns = analyze_stmt_list(stmt.stmts, localenv, returns)
            if block_returns then
                return true
            end
            -- Fallthrough.

        elseif stmt.tag == NT.VARDECL then
            local vartype = resolve_type(stmt.vartype)
            local et = check_expr(stmt.init, tenv)
            assert_eq(vartype, et)
            tenv:define(stmt.name, et)
            -- Fallthrough.

        elseif stmt.tag == NT.WHILE then
            local ct = check_expr(stmt.cond, tenv)
            assert_eq(ct, primitives.Bool, "while condition not bool")
            analyze_stmt_list({stmt.body}, tenv, returns)
            -- Fallthrough.

        elseif stmt.tag == NT.EXPR_STMT then
            check_expr(stmt.expr, tenv)
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
        -- NOTE: Not necessary an error if the return type is Unit.
        if fty.ret.tag ~= InternalTags.UNIT then
            TypeCheckError("function may not return")
        end
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
                param_types[i] = resolve_type(stmt.params[i].type)
            end
            local fty = FnType(param_types, resolve_type(stmt.rettype))    -- TODO: Clean up.
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
