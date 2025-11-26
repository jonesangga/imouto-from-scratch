local util = {}

function util.getFileNames(path, includePath)
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

function util.splitLines(s)
    assert(type(s) == "string")

    local lines = {}
    for line in (s .. "\n"):gmatch("(.-)\r?\n") do
        table.insert(lines, line)
    end
    return lines
end

return util
