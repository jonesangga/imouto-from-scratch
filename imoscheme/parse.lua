local types = require("types")
local List, Quote, Symbol = types.List, types.Quote, types.Symbol

local function parse(tokens)
    local i = 1

    local function parse_expr()
        local tok = tokens[i]
        if not tok then error("unexpected EOF while reading") end
        i = i + 1

        if tok.type == "lparen" then
            local list = {}
            while tokens[i] do
                if tokens[i].type == "rparen" then
                    i = i + 1  -- Skip ')'.
                    return List.from(list)
                end
                table.insert(list, parse_expr())
            end
            error("missing )")

        elseif tok.type == "rparen" then
            error("unexpected )")

        elseif tok.type == "boolean" then
            return tok.value == "#t"

        elseif tok.type == "quote" then
            return Quote.new(parse_expr())

        elseif tok.type == "string" then
            return tok.value

        elseif tok.type == "number" then
            return tonumber(tok.value)
        else
            return Symbol.new(tok.value)
        end
    end

    local exprs = {}
    while i <= #tokens do
        table.insert(exprs, parse_expr())
    end
    return exprs
end

return parse
