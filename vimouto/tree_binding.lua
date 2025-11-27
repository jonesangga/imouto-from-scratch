local treeBindings = {}

treeBindings["tab"] = function(buf)
    buf.parent.mode = "NORMAL"
    buf.parent.showTree = not buf.parent.showTree
end

treeBindings["return"] = function(buf)
    buf.parent.open(buf.lines[buf.cy])
    buf.parent.mode = "NORMAL"
    buf.parent.treeFocus = false
end

treeBindings["j"] = function(buf)
    buf.cy = buf.clamp(buf.cy + 1, 1, #buf.lines)
end
treeBindings["down"] = treeBindings["j"]

treeBindings["k"] = function(buf)
    buf.cy = buf.clamp(buf.cy - 1, 1, #buf.lines)
end
treeBindings["up"] = treeBindings["k"]

treeBindings["space"] = function(buf)
    buf.parent.mode = "NORMAL"
    buf.parent.treeFocus = false
end

return treeBindings
