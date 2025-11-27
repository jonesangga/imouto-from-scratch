local game = require("game")

local Tree = {}
Tree.__index = Tree

function Tree.new(parent)
    local buf = setmetatable({}, Tree)
    buf.parent = parent
    buf.cy = 1
    buf.scroll_y = 1
    buf.lines = {""}
    return buf
end

function Tree.clamp(n, a, b)
    return math.max(a, math.min(b, n))
end

return Tree
