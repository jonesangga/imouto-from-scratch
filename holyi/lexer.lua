local LexerError = require("error").LexerError
local TT = require("types").TT

local keywords = {
    ["else"]   = TT.ELSE,
    ["false"]  = TT.FALSE,
    ["for"]    = TT.FOR,
    ["if"]     = TT.IF,
    ["return"] = TT.RETURN,
    ["show"]   = TT.SHOW,
    ["true"]   = TT.TRUE,
    ["while"]  = TT.WHILE,
}

--[[ NOTE ]
| Below 3 functions work because the argument is guaranteed to be a string.
`--------------------------------------------------------------------------]]

local function is_digit(c)
    local b = c:byte()
    return b and 48 <= b and b <= 57  -- 0-9
end

local function is_alpha(c)
    local b = c:byte()
    return b and ((65 <= b and b <= 90)      -- A-Z
                  or (97 <= b and b <= 122)  -- a-z
                  or b == 95)                -- underscore (_)
end

local function is_upper(c)
    local b = c:byte()
    return b and 65 <= b and b <= 90  -- A-Z
end

local function is_alnum(c)
    return is_alpha(c) or is_digit(c)
end


--[[ TODO ]
| + Support multiline comment.
`-----------------------------]]

local function lexer(src)
    local start   = 1
    local current = 1
    local length  = #src
    local line    = 1
    local tokens  = {}

    local function eof()       return current > length                                              end
    local function advance()   local c = src:sub(current, current); current = current + 1; return c end
    local function peek()      return src:sub(current, current)                                     end
    local function peek_next() return src:sub(current + 1, current + 1)                             end

    local function match(expect)
        if eof() or peek() ~= expect then
            return false
        end
        current = current + 1;
        return true;
    end

    local function token(type)
        table.insert(tokens, { type = type, line = line })
    end

    local function token_literal(type, val)
        table.insert(tokens, { type = type, val  = val, line = line })
    end

    local function skip_whitespace()
        while true do
            local c = peek()
            if c == ' ' or c == '\t' or c == '\r' then
                advance()
            elseif c == '\n' then
                line = line + 1
                advance()
            elseif c == '/' then
                if peek_next() == '/' then
                    while peek() ~= '\n' and not eof() do
                        advance()
                    end
                else
                    break
                end
            else
                break
            end
        end
    end

    local ops = {}
    ops[")"] = function() token(TT.RPAREN) end
    ops["{"] = function() token(TT.LBRACE) end
    ops["}"] = function() token(TT.RBRACE) end
    ops[";"] = function() token(TT.SEMICOLON) end
    ops[","] = function() token(TT.COMMA) end
    ops["+"] = function() token(TT.PLUS) end
    ops["-"] = function() token(TT.MINUS) end
    ops["*"] = function() token(TT.STAR) end
    ops["/"] = function() token(TT.SLASH) end
    ops["("] = function() token(match(')') and TT.LRPAREN    or TT.LPAREN) end
    ops["."] = function() token(match('.') and TT.DOT2       or TT.DOT) end
    ops["="] = function() token(match('=') and TT.EQ_EQ      or TT.EQ) end
    ops["!"] = function() token(match('=') and TT.NOT_EQ     or TT.NOT) end
    ops["<"] = function() token(match('=') and TT.LESS_EQ    or TT.LESS) end
    ops[">"] = function() token(match('=') and TT.GREATER_EQ or TT.GREATER) end
    ops["&"] = function() token(match('&') and TT.AMP2       or TT.AMP) end
    ops["|"] = function() token(match('|') and TT.PIPE2      or TT.PIPE) end

    while true do
        skip_whitespace()
        start = current

        if eof() then break end

        local c = advance()

        if ops[c] then
            ops[c]()

        -- Number type.
        elseif is_digit(c) or ((c == '+' or c == '-') and is_digit(peek())) then
            if c == '+' or c == '-' then
                advance()
            end
            while is_digit(peek()) do
                advance()
            end

            -- TODO: Add this later. Optional fractional part.
            -- if peek() == '.' and is_digit(peek_next()) then
                -- advance()
                -- while is_digit(peek()) do
                    -- advance()
                -- end
            -- end
            token_literal(TT.INT, tonumber(src:sub(start, current - 1)))

        -- String literal. Doesn't support multiline string.
        elseif c == '"' then
            local s = ""
            local next = peek()

            while true do
                if next == '"' then
                    break
                end
                if eof() or next == '\n' then
                    LexerError("unterminated string", line)
                end

                local d = advance()
                if d == '\\' then
                    -- Got escape sequences.
                    local e = advance()

                    if     e == 'n'  then s = s .. '\n'
                    elseif e == 't'  then s = s .. '\t'
                    elseif e == '"'  then s = s .. '"'
                    elseif e == '\\' then s = s .. '\\'
                    else                  LexerError("invalid escape sequence", line)
                    end
                else
                    s = s .. d
                end

                next = peek()
            end

            advance()  -- Closing quote.
            token_literal(TT.STRING, s)

        -- Keywords, types, and identifiers.
        elseif is_alpha(c) then
            while is_alnum(peek()) do
                advance()
            end

            local s = src:sub(start, current - 1)
            if is_upper(c) then
                token_literal(TT.TYPE, s)
            else
                if keywords[s] then
                    token(keywords[s])
                else
                    token_literal(TT.IDENT, s)
                end
            end
        end
    end

    return tokens
end

return lexer
