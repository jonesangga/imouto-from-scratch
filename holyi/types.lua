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
    "INT", "STRING", "TRUE", "FALSE", "NULL",
    "PLUS", "MINUS", "STAR", "SLASH",
    "LPAREN", "RPAREN", "LBRACE", "RBRACE",
    "SEMICOLON", "COMMA", "DOT",
    "EQ", "EQ_EQ", "NOT", "NOT_EQ", "LESS", "LESS_EQ", "GREATER", "GREATER_EQ",
    "IDENT", "PRINTLN",
}

local NodeTypes = Enum{
    "PRINTLN", "EXPR_STMT",
    "INT", "BOOL", "STRING", "NULL",
    "BINARY", "UNARY", "GROUP",
}

local InternalTypes = Enum{
    "INT", "BOOL", "STRING",
}

return {
    TT = TokenTypes,
    NT = NodeTypes,
    IT = InternalTypes,
}
