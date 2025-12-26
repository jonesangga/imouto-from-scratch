local TypeCheckError = require("error").TypeCheckError

local StrictMT = {
    __index = function(t, k)
        error("access to undefined key '" .. tostring(k) .. "'", 2)
    end,

    __newindex = function(t, k, v)
        error("assign to undefined key '" .. tostring(k) .. "'", 2)
    end,
}

-- Create enum with reverse lookup.
local function Enum(list)
    local t = {}
    for i, name in ipairs(list) do
        t[name] = i
        t[i] = name
    end
    return setmetatable(t, StrictMT)
end

local TokenTypes = Enum{
    "TYPE", "INT", "STRING", "TRUE", "FALSE", "NULL",
    "PLUS", "MINUS", "STAR", "SLASH",
    "PLUS_EQ", "MINUS_EQ", "STAR_EQ", "SLASH_EQ",
    "LPAREN", "RPAREN", "LRPAREN", "LBRACE", "RBRACE", "LSQUARE", "RSQUARE",
    "SEMICOLON", "COMMA", "HASH", "DOT", "DOT2",
    "EQ", "EQ_EQ", "NOT", "NOT_EQ", "LESS", "LESS_EQ", "GREATER", "GREATER_EQ",
    "IDENT", "SHOW",
    "IF", "ELSE", "AMP", "AMP2", "PIPE", "PIPE2",
    "WHILE", "FOR", "RETURN",
}

local NodeTags = Enum{
    "SHOW", "EXPR_STMT", "BLOCK",
    "INT", "BOOL", "STRING", "NULL", "UNIT", "ARRAY",
    "BINARY", "UNARY", "GROUP", "VAR", "VARDECL", "FUNDECL", "ASSIGN",
    "IF", "WHILE", "INDEX", "CALL", "RETURN",
}

-- TODO: Think a better name.
local InternalTags = Enum{
    "INT", "BOOL", "STRING", "NULL", "UNIT", "ANY", "FN", "GENERIC_FN", "ARRAY", "TYPEVAR",
}

local primitives = {
    Any    = { tag = InternalTags.ANY },
    Bool   = { tag = InternalTags.BOOL },
    Int    = { tag = InternalTags.INT },
    Null   = { tag = InternalTags.NULL },
    String = { tag = InternalTags.STRING },
    Unit   = { tag = InternalTags.UNIT },
}

local function FnType(params, ret)
    return { tag = InternalTags.FN, params = params, ret = ret }
end

local function TypeVar(name)
    return { tag = InternalTags.TYPEVAR, name = name }
end

local function GenericFnType(tparams, params, ret)
    return { tag = InternalTags.GENERIC_FN, tparams = tparams, params = params, ret = ret }
end

local function ArrayType(eltype)
    return { tag = InternalTags.ARRAY, eltype = eltype }
end

local function assert_eq(a, b, msg)
    if a.tag == InternalTags.ANY or b.tag == InternalTags.ANY then
        return
    end
    if a.tag ~= b.tag then
        TypeCheckError(msg .. ", expect " .. InternalTags[b.tag] .. " got " .. InternalTags[a.tag])
    end
    if a.tag == InternalTags.ARRAY then
        assert_eq(a.eltype, b.eltype, "array element type mismatch")
    end
end


-- Value Classes.

local Int = {
    __tostring = function(o)
        return o.val
    end
}
Int.__index = Int

function Int.new(n)
    return setmetatable({ type = InternalTags.INT, val = n }, Int)
end

local String = {
    __tostring = function(o)
        return o.val
    end
}
String.__index = String

function String.new(s)
    return setmetatable({ type = InternalTags.STRING, val = s }, String)
end

local Bool = {
    __tostring = function(o)
        return tostring(o.val)
    end
}
Bool.__index = Bool

function Bool.new(b)
    return setmetatable({ type = InternalTags.BOOL, val = b }, Bool)
end

local Unit = {
    __tostring = function(o)
        return o.val
    end
}
Unit.__index = Unit

-- Unit only has one value. We don't need constructor.
local unit = setmetatable({ type = InternalTags.UNIT, val = "()" }, Unit)

local Array = {
    __tostring = function(a)
        if #a.val == 0 then
            return "[]"
        end

        local array = a.val

        local text = "[" .. tostring(array[1])
        for i = 2, #array do
            text = text .. ", " .. tostring(array[i])
        end
        return text .. "]"
    end
}
Array.__index = Array

function Array.new(t)
    return setmetatable({ type = InternalTags.ARRAY, val = t }, Array)
end

return {
    TT = TokenTypes,
    NT = NodeTags,
    InternalTags = InternalTags,
    FnType = FnType,
    GenericFnType = GenericFnType,
    TypeVar = TypeVar,
    ArrayType = ArrayType,
    assert_eq = assert_eq,
    Int = Int,
    Bool = Bool,
    String = String,
    Array = Array,
    unit = unit,
    primitives = primitives,
}
