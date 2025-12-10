local util = {}

-- Make it error when accessing undefined key or defining new key.
-- NOTE: You should not do like t.a = nil.
local StrictMT = {
    __index = function(t, k)
        error("access to undefined key '" .. tostring(k) .. "'", 2)
    end,

    __newindex = function(t, k, v)
        error("assign to undefined key '" .. tostring(k) .. "'", 2)
    end,
}

function util.strict(table)
    return setmetatable(table or {}, StrictMT)
end

function util.get_file_names(path, includePath)
    local items = love.filesystem.getDirectoryItems(path)
    local filenames = {}

    for _, name in ipairs(items) do
        local full = (path == "" and name) or (path .. "/" .. name)
        local info = love.filesystem.getInfo(full)
        if info.type == "file" then
            if includePath then
                table.insert(filenames, full)
            else
                table.insert(filenames, name)
            end
        end
    end

    return filenames
end

function util.split_lines(s)
    assert(type(s) == "string")

    local lines = {}
    for line in (s .. "\n"):gmatch("(.-)\r?\n") do
        table.insert(lines, line)
    end
    return lines
end

return util.strict(util)
