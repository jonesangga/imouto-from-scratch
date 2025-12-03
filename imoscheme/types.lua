local Symbol = {
    __eq = function(x, y) return x.name == y.name end,
    __tostring = function(s) return s.name end,
}
Symbol.__index = Symbol

function symbol(name)
    return setmetatable({ name = name }, Symbol)
end


local Quote = {
    __eq = function(x, y) return x.value == y.value end,
    __tostring = function(q) return "'" .. tostring(q.value) end,
}
Quote.__index = Quote

function quote(obj)
    return setmetatable({ value = obj }, Quote)
end


local EMPTY = setmetatable({}, {
    __tostring = function(e) return "()" end,
})

local function is_empty(x)
    return rawequal(x, EMPTY)
end


local Pair = {
    __eq = function(x, y)
        while is_pair(x) and is_pair(y) do
            if x.car ~= y.car then
                return false
            end
            x, y = x.cdr, y.cdr
        end
        return is_empty(x) and is_empty(y)
    end,
 
    __tostring = function(x)
        local strs = {}
        while is_pair(x) do
            table.insert(strs, tostring(x.car))
            x = x.cdr
        end
        if is_empty(x) then
            return "(" .. table.concat(strs, " ") .. ")"
        else
            -- Dotted/improper list.
            return "(" .. table.concat(strs, " ") .. " . " .. tostring(x) .. ")"
        end
    end
}
Pair.__index = Pair

function is_pair(x)
    return type(x) == "table" and getmetatable(x) == Pair
end

function pair(a, b)
    return setmetatable({ car = a, cdr = b }, Pair)
end

local function list(arr)
    local list = EMPTY
    for i = #arr, 1, -1 do
        list = pair(arr[i], list)
    end
    return list
end

local function is_symbol(x)
    return type(x) == "table" and getmetatable(x) == Symbol
end

local function is_quote(x)
    return type(x) == "table" and getmetatable(x) == Quote
end

local function is_list(x)
    local cur = x
    while true do
        if is_empty(cur) then return true end
        if not is_pair(cur) then return false end
        cur = cur.cdr
    end
end


return {
    EMPTY = EMPTY,
    pair = pair,
    list = list,
    quote = quote,
    symbol = symbol,
    is_pair = is_pair,
    is_list = is_list,
    is_quote = is_quote,
    is_symbol = is_symbol,
    is_empty = is_empty,
}
