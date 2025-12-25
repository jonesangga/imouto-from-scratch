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
    "LPAREN", "RPAREN", "LRPAREN", "LBRACE", "RBRACE",
    "SEMICOLON", "COMMA", "DOT", "DOT2",
    "EQ", "EQ_EQ", "NOT", "NOT_EQ", "LESS", "LESS_EQ", "GREATER", "GREATER_EQ",
    "IDENT", "SHOW",
    "IF", "ELSE", "AMP", "AMP2", "PIPE", "PIPE2",
    "WHILE", "FOR", "RETURN",
}

local NodeTags = Enum{
    "SHOW", "EXPR_STMT", "BLOCK",
    "INT", "BOOL", "STRING", "NULL", "UNIT",
    "BINARY", "UNARY", "GROUP", "VAR", "VARDECL", "FUNDECL", "ASSIGN",
    "IF", "WHILE", "CALL", "RETURN",
}

-- TODO: Think a better name.
local InternalTags = Enum{
    "INT", "BOOL", "STRING", "NULL", "UNIT", "ANY", "FN",
}

-- These are fixed. These are indexed to get the type in vardecl.
-- TODO: Think again.
local InternalTypes = {
    Int    = { tag = InternalTags.INT },
    Bool   = { tag = InternalTags.BOOL },
    String = { tag = InternalTags.STRING },
    Null   = { tag = InternalTags.NULL },
    Unit   = { tag = InternalTags.UNIT },
    Any    = { tag = InternalTags.ANY },
}

local function FnType(params, ret)
    return { tag = InternalTags.FN, params = params, ret = ret }
end

local function assert_eq(a, b, msg)
    if a.tag == InternalTags.ANY or b.tag == InternalTags.ANY then
        return
    end
    if a.tag ~= b.tag then
        TypeCheckError(msg .. ", expect " .. InternalTags[b.tag] .. " got " .. InternalTags[a.tag])
    end
end

-- Value constructor.
local function Int(n)    return { type = InternalTags.INT,    val = n }    end
local function Bool(b)   return { type = InternalTags.BOOL,   val = b }    end
local function String(s) return { type = InternalTags.STRING, val = s }    end
local function Unit()    return { type = InternalTags.UNIT,   val = "()" } end
local function Null()    return { type = InternalTags.NULL }               end

return {
    TT = TokenTypes,
    NT = NodeTags,
    IT = InternalTypes,
    InternalTags = InternalTags,
    FnType = FnType,
    assert_eq = assert_eq,
    Int = Int,
    Bool = Bool,
    String = String,
    Null = Null,
    Unit = Unit,
}
