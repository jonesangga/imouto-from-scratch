local TypeCheckError = require("error").TypeCheckError
local inspect = require("libraries/inspect")
local types = require("types")

local TT, NT, primitives = types.TT, types.NT, types.primitives
local InternalTags = types.InternalTags
local assert_eq = types.assert_eq
local FnType = types.FnType
local GenericFnType = types.GenericFnType
local ArrayType = types.ArrayType
local TypeVar = types.TypeVar

function resolve_type(t)
    if type(t) == "string" then
        if primitives[t] then
            return primitives[t]
        end
        TypeCheckError("unresolved type " .. t)
    elseif t.kind == "array" then
        return ArrayType(resolve_type(t.name))
    else
        error("type kind not implemented: " .. t.kind)
    end
end

local function contains(arr, value)
    for i = 1, #arr do
        if arr[i] == value then return true end
    end
    return false
end

function resolve_type_generic(t, tparams)
    if type(t) == "string" then
        if contains(tparams, t) then
            return TypeVar(t)
        end
        if primitives[t] then
            return primitives[t]
        end
        TypeCheckError("unresolved type " .. t)
    elseif t.kind == "array" then
        return ArrayType(resolve_type_generic(t.name, tparams))
    else
        error("type kind not implemented: " .. t.kind)
    end
end

function resolve_generic(arg, param, subst)
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
        resolve_generic(arg.eltype, param.eltype, subst)
    end
end

local function check_expr(expr, tenv)
    local t = expr.tag

    if t == NT.INT or t == NT.BOOL or t == NT.STRING or t == NT.UNIT then
        return expr.type

    -- Only support array of primitive type.
    -- TODO: support multidimensional array of primitive type.
    elseif t == NT.ARRAY then
        local el_type = primitives.Any
        for _, el in ipairs(expr.array) do
            local t = check_expr(el, tenv)
            assert_eq(el_type, t)
            el_type = t
        end
        return ArrayType(el_type)

    elseif t == NT.VAR then
        return tenv:get(expr.name)

    elseif t == NT.ASSIGN then
        local type = tenv:get(expr.name)
        local et = check_expr(expr.value, tenv)
        assert_eq(type, et)
        local op = expr.op
        if op ~= TT.EQ then
            assert_eq(type, primitives.Int)
        end
        return type

    elseif t == NT.GROUP then
        return check_expr(expr.expr, tenv)

    elseif t == NT.INDEX then
        local it = check_expr(expr.index, tenv)
        assert_eq(it, primitives.Int, "index type")
        local bt = check_expr(expr.base, tenv)
        if bt.tag ~= InternalTags.ARRAY then
            TypeCheckError("can only index array")
        end
        return bt.eltype

    -- TODO: Refactor.
    elseif t == NT.CALL then
        local fty = check_expr(expr.callee, tenv)
        if not fty then
            error("call of undefined function")
        end

        if fty.tag == InternalTags.FN then
            if #expr.args ~= #fty.params then
                error("arg count mismatch")
            end
            for i = 1, #expr.args do
                local at = check_expr(expr.args[i], tenv)
                assert_eq(at, fty.params[i], "arg " .. i .. " type mismatch")
            end
            return fty.ret

        elseif fty.tag == InternalTags.GENERIC_FN then
            if #expr.args ~= #fty.params then
                error("arg count mismatch")
            end

            local tparams = fty.tparams
            local gparams = fty.params
            local args = expr.args

            local subst = {}
            for i = 1, #gparams do
                local at = check_expr(args[i], tenv)
                resolve_generic(at, gparams[i], subst)
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

    elseif t == NT.UNARY then
        local rt = check_expr(expr.right, tenv)
        local op = expr.op

        if op == TT.MINUS then
            assert_eq(rt, primitives.Int)
            return rt
        elseif op == TT.NOT then
            assert_eq(rt, primitives.Bool)
            return rt
        elseif op == TT.HASH then
            if rt.tag ~= InternalTags.STRING and rt.tag ~= InternalTags.ARRAY then
                TypeCheckError("operator # only for String and Array")
            end
            return primitives.Int
        end

    elseif t == NT.BINARY then
        local lt = check_expr(expr.left, tenv)
        local rt = check_expr(expr.right, tenv)
        local op = expr.op

        if op == TT.PLUS or op == TT.MINUS or op == TT.STAR or op == TT.SLASH or op == TT.PERCENT then
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

function check_stmt(stmt, tenv, returns)
    local t = stmt.tag

    if t == NT.RETURN then
        local type = stmt.expr and check_expr(stmt.expr, tenv) or primitives.Unit
        table.insert(returns, type)
        return true

    elseif t == NT.IF then
        local cond_type = check_expr(stmt.cond, tenv)
        assert_eq(cond_type, primitives.Bool, "if condition not Bool")

        local then_returns = check_stmt(stmt.then_, tenv, returns)
        if stmt.else_ then
            else_returns = check_stmt(stmt.else_, tenv, returns)
            if then_returns and else_returns then
                return true
            end
        end
        -- Fallthrough.

    elseif t == NT.BLOCK then
        local localenv = tenv:branch()
        local block_returns = check_stmt_list(stmt.stmts, localenv, returns)
        if block_returns then
            return true
        end
        -- Fallthrough.

    elseif t == NT.VARDECL then
        local var_type = resolve_type(stmt.var_type)
        local init_type = check_expr(stmt.init, tenv)
        assert_eq(init_type, var_type, "vardecl mismatch")
        tenv:define(stmt.name, init_type)
        -- Fallthrough.

    elseif t == NT.WHILE then
        local cond_type = check_expr(stmt.cond, tenv)
        assert_eq(cond_type, primitives.Bool, "while condition not Bool")
        check_stmt(stmt.body, tenv, returns)
        -- Fallthrough.

    elseif t == NT.EXPR_STMT then
        check_expr(stmt.expr, tenv)

    elseif t == NT.SHOW then
        check_expr(stmt.expr, tenv)

    else
        error("stmt typecheck not implemented: " .. NT[t])
    end
end

-- TODO: How to pass specific error like in if stmt? Should it be the first fallthrough?
function check_stmt_list(stmt_list, tenv, returns)
    for i, stmt in ipairs(stmt_list) do
        if check_stmt(stmt, tenv, returns) then
            return true
        end
    end

    return false
end

-- TODO: Clean up. Rename.
local function check_function_returns(stmt, tenv)
    local fn_type = stmt.type
    local localenv = tenv:branch()
    for i, param in ipairs(stmt.params) do
        localenv:define(param.name, fn_type.params[i])
    end

    -- Collect return types while typechecking body.
    local returns = {}
    local always = check_stmt_list(stmt.body, localenv, returns)

    if not always then
        -- NOTE: It is not necessary an error if the return type is Unit.
        if fn_type.ret.tag ~= InternalTags.UNIT then
            TypeCheckError("function may not return")
        end
    end

    for _, type in ipairs(returns) do
        assert_eq(type, fn_type.ret)
    end
end

local function typecheck(ast, tenv)
    -- Add function signatures to tenv.
    for _, stmt in ipairs(ast) do
        if stmt.tag == NT.FUNDECL then
            local param_types = {}
            for _, param in ipairs(stmt.params) do
                table.insert(param_types, resolve_type(param.type))
            end

            local fn_type = FnType(param_types, resolve_type(stmt.return_type))
            stmt.type = fn_type
            tenv:define(stmt.name, fn_type)

        elseif stmt.tag == NT.GENFUNDECL then
            local tparams = stmt.tparams

            local param_types = {}
            for _, param in ipairs(stmt.params) do
                table.insert(param_types, resolve_type_generic(param.type, tparams))
            end

            -- This assumes the return type is not a typevar.
            local fn_type = GenericFnType(tparams, param_types, resolve_type_generic(stmt.return_type, tparams))
            stmt.type = fn_type
            tenv:define(stmt.name, fn_type)
        end
    end

    -- Typecheck function bodies and annotate nodes.
    for _, stmt in ipairs(ast) do
        if stmt.tag == NT.FUNDECL then
            check_function_returns(stmt, tenv)
        elseif stmt.tag == NT.GENFUNDECL then
            -- TODO: This is not correct but works. Think later.
            check_function_returns(stmt, tenv)
        else
            -- TODO: This should be a special case of check_function_returns().
            check_stmt(stmt, tenv, nil)
        end
    end
end

return typecheck
