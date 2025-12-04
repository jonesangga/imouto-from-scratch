local function Set(list)
    local set = {}
    for _, elem in ipairs(list) do
        set[elem] = true
    end
    return set
end

local whitespace = Set { " ", "\t", "\n", "\r" }
local wordend    = Set { "(", ")", "'", ",", ";", "\"" }
local digit      = Set { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }

local function tokenize(src)
    local start   = 1
    local current = 1
    local length  = #src
    local line    = 1
    local tokens  = {}

    local function eof()       return current > length                                              end
    local function advance()   local c = src:sub(current, current); current = current + 1; return c end
    local function peek()      return src:sub(current, current)                                     end
    local function peek_next() return src:sub(current + 1, current + 1)                             end

    local function token(type)
        table.insert(tokens, {
            type  = type,
            value = src:sub(start, current - 1),
            line  = line,
        })
    end

    local function token_string(value)
        table.insert(tokens, {
            type  = "string",
            value = value,
            line  = line,
        })
    end

    local function skip_whitespace()
        while true do
            local c = peek()
            if c == ' ' or c == '\t' or c == '\r' then
                advance()
            elseif c == '\n' then
                line = line + 1
                advance()
            else
                break
            end
        end
    end

    while true do
        -- print(start, current)
        skip_whitespace()
        start = current

        if eof() then break end

        local c = advance()

        if c == '(' then
            token("lparen")
        elseif c == ')' then
            token("rparen")
        elseif c == '#' and peek():match('[tf]') then
            local val = advance()
            token("boolean")

        -- Character type.
        elseif c == '#' and peek() == "\\" and peek_next() ~= " " then
            advance()  -- Consume \.
            local d = peek()
            if d:match("%a") then
                advance()
                while not eof() do
                    local e = peek()
                    if whitespace[e] or wordend[e] then
                        break
                    end
                    advance()
                end
            else
                advance()
            end
            token("char")

        elseif digit[c] or ((c == '+' or c == '-') and digit[peek()]) then
            if c == '+' or c == '-' then
                advance()
            end
            while digit[peek()] do
                advance()
            end

            -- Optional fractional part.
            if peek() == '.' and digit[peek_next()] then
                advance()
                while digit[peek()] do
                    advance()
                end
            end
            token("number")

        elseif c == '\'' then
            token("quote")

        elseif c == '"' then
            local s = ""
            while not eof() and peek() ~= '"' do
                local d = advance()
                if d == '\\' then
                    local e = advance()
                    if e == 'n' then s = s .. '\n'
                    elseif e == 't' then s = s .. '\t'
                    elseif e == '"' then s = s .. '"'
                    elseif e == '\\' then s = s .. '\\'
                    else s = s .. e  -- Implementation defined.
                    end
                else
                    s = s .. d
                end
            end

            if eof() then error("unterminated string") end
            advance()  -- Closing quote.
            token_string(s)

        else
            while not eof() do
                local c = peek()
                if whitespace[c] or wordend[c] then
                    break
                end
                advance()
            end
            token("symbol")
        end
    end

    return tokens
end

return tokenize
