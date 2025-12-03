local types = require("types")
local list, quote, symbol = types.list, types.quote, types.symbol

local function parse(tokens)
    local i = 1

    local function parse_expr()
        local tok = tokens[i]
        if not tok then error("unexpected EOF while reading") end
        i = i + 1

        if tok.type == "lparen" then
            local arr = {}
            while tokens[i] do
                if tokens[i].type == "rparen" then
                    i = i + 1  -- Skip ')'.
                    return list(arr)
                end
                table.insert(arr, parse_expr())
            end
            error("missing )")

        elseif tok.type == "rparen" then
            error("unexpected )")

        elseif tok.type == "boolean" then
            return tok.value == "#t"

        elseif tok.type == "quote" then
            return quote(parse_expr())

        elseif tok.type == "string" then
            return tok.value

        elseif tok.type == "number" then
            return tonumber(tok.value)
        else
            return symbol(tok.value)
        end
    end

    local exprs = {}
    while i <= #tokens do
        table.insert(exprs, parse_expr())
    end
    return exprs
end

return parse
