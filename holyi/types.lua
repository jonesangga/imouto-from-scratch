-- Create enum with reverse lookup.
local function Enum(list)
    local t = {}
    for i, name in ipairs(list) do
        t[name] = i
        t[i] = name
    end
    return t
end

local TokenTypes = Enum{
    "TYPE", "INT", "STRING", "TRUE", "FALSE", "NULL",
    "PLUS", "MINUS", "STAR", "SLASH",
    "LPAREN", "RPAREN", "LBRACE", "RBRACE",
    "SEMICOLON", "COMMA", "DOT",
    "EQ", "EQ_EQ", "NOT", "NOT_EQ", "LESS", "LESS_EQ", "GREATER", "GREATER_EQ",
    "IDENT", "PRINTLN",
    "IF", "ELSE",
}

local NodeTags = Enum{
    "PRINTLN", "EXPR_STMT", "BLOCK",
    "INT", "BOOL", "STRING", "NULL",
    "BINARY", "UNARY", "GROUP", "VAR", "VARDECL", "ASSIGN",
    "IF",
}

local InternalTags = Enum{
    "INT", "BOOL", "STRING", "NULL", "FN",
}

-- TODO: Think again.
local InternalTypes = {
    Int    = { tag = InternalTags.INT },
    Bool   = { tag = InternalTags.BOOL },
    String = { tag = InternalTags.STRING },
    Null   = { tag = InternalTags.NULL },
}

return {
    TT = TokenTypes,
    NT = NodeTags,
    IT = InternalTypes,
}
