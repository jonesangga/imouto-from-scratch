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
    "LPAREN", "RPAREN", "LBRACE", "RBRACE",
    "SEMICOLON", "COMMA", "DOT", "DOT2",
    "EQ", "EQ_EQ", "NOT", "NOT_EQ", "LESS", "LESS_EQ", "GREATER", "GREATER_EQ",
    "IDENT", "SHOW",
    "IF", "ELSE", "AMP", "AMP2", "PIPE", "PIPE2",
    "WHILE", "FOR",
}

local NodeTags = Enum{
    "SHOW", "EXPR_STMT", "BLOCK",
    "INT", "BOOL", "STRING", "NULL",
    "BINARY", "UNARY", "GROUP", "VAR", "VARDECL", "FUNDECL", "ASSIGN",
    "IF", "WHILE", "CALL",
}

-- TODO: Think a better name.
local InternalTags = Enum{
    "INT", "BOOL", "STRING", "NULL", "ANY", "VOID", "FN",
}

-- These are fixed. These are indexed to get the type in vardecl.
-- TODO: Think again.
local InternalTypes = {
    Int    = { tag = InternalTags.INT },
    Bool   = { tag = InternalTags.BOOL },
    String = { tag = InternalTags.STRING },
    Null   = { tag = InternalTags.NULL },
    Void   = { tag = InternalTags.VOID },
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
        error(msg or "type not match")
    end
end

return {
    TT = TokenTypes,
    NT = NodeTags,
    IT = InternalTypes,
    InternalTags = InternalTags,
    FnType = FnType,
    assert_eq = assert_eq,
}
