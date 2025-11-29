local types = require("types")
local List, Symbol = types.List, types.Symbol

local function tokenize(src)
    local src, _ = src:gsub('%(', ' ( ')
                      :gsub('%)', ' ) ')
                      :gsub("'", " ' ")
    local tokens = {}
    for token in src:gmatch('%S+') do
        table.insert(tokens, token)
    end
    return tokens
end

local function parse(src)
    local tokens = tokenize(src)
    local i = 1

    local function parse_expr()
        local tok = tokens[i]
        if not tok then error("unexpected EOF while reading") end
        i = i + 1

        if tok == "(" then
            local list = {}
            while tokens[i] ~= ")" do
                if not tokens[i] then error("missing )") end
                table.insert(list, parse_expr())
            end
            i = i + 1
            return List.from(list)

        elseif tok == ")" then
            error("unexpected )")

        elseif tok == "#t" then
            return true

        elseif tok == "#f" then
            return false
        end

        return tonumber(tok) or Symbol.new(tok)
    end

    local exprs = {}
    while i <= #tokens do
        table.insert(exprs, parse_expr())
    end
    return exprs
end

return parse
