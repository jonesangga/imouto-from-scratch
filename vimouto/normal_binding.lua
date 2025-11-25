local normalBindings = {}
local pendings = {}
normalBindings.pendings = pendings

normalBindings["d"] = function(buf)
    buf.cmdbuf = "d"
    buf.remembercx = false
end

pendings["d"] = {
    ["d"] = function(buf)
        buf:delete_line(buf.cy)
        buf.cmdbuf = ""
    end,
}

normalBindings["g"] = function(buf)
    if love.keyboard.isDown("lshift", "rshift") then
        buf.cy = #buf.lines
        buf.cx = 1
    else
        buf.cmdbuf = "g"
    end
    buf.remembercx = false
end

pendings["g"] = {
    ["g"] =  function(buf)
        buf.cy = 1
        buf.cx = 1
    end,
}

normalBindings["j"] = function(buf)
    buf.cy = buf.clamp(buf.cy + 1, 1, #buf.lines)
    if not buf.remembercx then
        buf.remembercx = true
        buf.cxBeforeMoveLine = buf.cx
    end
    buf:clampCursor()
end
normalBindings["down"] = normalBindings["j"]

normalBindings["k"] = function(buf)
    buf.cy = buf.clamp(buf.cy - 1, 1, #buf.lines)
    if not buf.remembercx then
        buf.remembercx = true
        buf.cxBeforeMoveLine = buf.cx
    end
    buf:clampCursor()
end
normalBindings["up"] = normalBindings["k"]

normalBindings["h"] = function(buf)
    buf.cx = buf.clamp(buf.cx - 1, 1, #buf.lines[buf.cy])
    buf.remembercx = false
end
normalBindings["left"] = normalBindings["h"]

normalBindings["l"] = function(buf)
    buf.cx = buf.clamp(buf.cx + 1, 1, #buf.lines[buf.cy])
    buf.remembercx = false
end
normalBindings["right"] = normalBindings["l"]

normalBindings["i"] = function(buf)
    if love.keyboard.isDown("lshift", "rshift") then
        buf.blocked_chars["I"] = true
        buf.cx = 1
    else
        buf.blocked_chars["i"] = true
    end
    buf.parent.mode = "INSERT"
    buf.remembercx = false
    buf.parent.showMessage = false
end

normalBindings["a"] = function(buf)
    if love.keyboard.isDown("lshift", "rshift") then
        buf.blocked_chars["A"] = true
        buf.cx = #buf.lines[buf.cy] + 1  -- NOTE: The case for empty line already included here.
    else
        buf.blocked_chars["a"] = true
        if #buf.lines[buf.cy] == 0 then
            buf.cx = 1
        else
            buf.cx = buf.cx + 1
        end
    end
    buf.parent.mode = "INSERT"
    buf.remembercx = false
    buf.parent.showMessage = false
end

normalBindings["o"] = function(buf)
    if love.keyboard.isDown("lshift", "rshift") then
        buf.blocked_chars["O"] = true
        table.insert(buf.lines, buf.cy, "")
        buf.cx = 1
    else
        buf.blocked_chars["o"] = true
        table.insert(buf.lines, buf.cy + 1, "")
        buf.cy = buf.cy + 1
        buf.cx = 1
    end
    buf.parent.mode = "INSERT"
    buf.remembercx = false
    buf.changed = true
    buf.parent.showMessage = false
end

normalBindings["x"] = function(buf)
    local line = buf.lines[buf.cy]
    local lineLen = #line
    buf.lines[buf.cy] = line:sub(1, buf.cx - 1) .. line:sub(buf.cx + 1)
    if buf.cx == lineLen and lineLen ~= 1 then
        buf.cx = buf.cx - 1
    end
    buf.remembercx = false
end

normalBindings["0"] = function(buf)
    buf.cx = 1
    buf.remembercx = false
end

normalBindings["4"] = function(buf)
    if love.keyboard.isDown("lshift", "rshift") then
        buf.cx = #buf.lines[buf.cy]
    end
    buf.remembercx = false
end

normalBindings[";"] = function(buf)
    if love.keyboard.isDown("lshift", "rshift") then
        buf.blocked_chars[":"] = true
        buf.parent.mode = "CMD"
        buf.cmdbuf = ""
        buf.parent.showMessage = false
    end
end

normalBindings["backspace"] = function(buf)
    if buf.cx > 1 then
        buf.cx = buf.cx - 1
    else
        -- Go to the end of previous line, if any.
        if buf.cy > 1 then
            buf.cy = buf.cy - 1
            buf.cx = #buf.lines[buf.cy]
            -- Handle empty line.
            if buf.cx == 0 then
                buf.cx = 1
            end
        end
    end
    buf.remembercx = false
end

return normalBindings
