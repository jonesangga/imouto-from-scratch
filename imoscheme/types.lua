local Symbol = {
    __eq = function(x, y)
        return x.name == y.name
    end,

    __tostring = function(s)
        return s.name
    end
}
Symbol.__index = Symbol

function Symbol.new(name)
    return setmetatable({ type = "symbol", name = name }, Symbol)
end


local Quote = {
    __eq = function(x, y)
        return x.value == y.value
    end,

    __tostring = function(q)
        return "'" .. tostring(q.value)
    end
}
Quote.__index = Quote

function Quote.new(obj)
    return setmetatable({ type = "quote", value = obj }, Quote)
end


local List = {
    __eq = function(x, y)
        while x.head ~= nil or y.head ~= nil do
            if x.head ~= y.head then
                return false
            end
            x, y = x.tail, y.tail
        end
        return true
    end,

    __tostring = function(list)
        local strs = {}
        while list.head ~= nil do
            table.insert(strs, tostring(list.head))
            list = list.tail
        end
        return "(" .. table.concat(strs, " ") .. ")"
    end
}
List.__index = List

function List.new()
    return setmetatable({ type = "list" }, List)
end

function List.from(arr)
    local list = List.new()
    for i = #arr, 1, -1 do
        list = list:prepend(arr[i])
    end
    return list
end

function List:prepend(val)
    local list = List.new()
    list.head = val
    list.tail = self
    return list
end

local function is_symbol(x)
    return type(x) == "table" and x.type == "symbol"
end

function is_quote(x)
    return type(x) == "table" and x.type == "quote"
end

local function is_list(x)
    return type(x) == "table" and x.type == "list"
end


return {
    List = List,
    Quote = Quote,
    Symbol = Symbol,
    is_list = is_list,
    is_quote = is_quote,
    is_symbol = is_symbol,
}
