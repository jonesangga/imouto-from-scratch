local insertBindings = {}

insertBindings["backspace"] = function(buf)
    local line = buf.buffer[buf.cy]
    if buf.cx > 1 then
        buf.buffer[buf.cy] = line:sub(1, buf.cx - 2) .. line:sub(buf.cx)
        buf.cx = buf.cx - 1
    else
        -- Join with previous line if present.
        if buf.cy > 1 then
            local prevlen = #buf.buffer[buf.cy - 1]
            buf.buffer[buf.cy - 1] = buf.buffer[buf.cy - 1] .. buf.buffer[buf.cy]
            table.remove(buf.buffer, buf.cy)
            buf.cy = buf.cy - 1
            buf.cx = prevlen + 1
        end
    end
end

insertBindings["return"] = function(buf)
    local line = buf.buffer[buf.cy]
    local a = line:sub(1, buf.cx - 1)
    local b = line:sub(buf.cx)
    buf.buffer[buf.cy] = a
    table.insert(buf.buffer, buf.cy + 1, b)
    buf.cy = buf.cy + 1
    buf.cx = 1
    print("enter pressed")
end
insertBindings["kpenter"] = insertBindings["return"]

insertBindings["escape"] = function(buf)
    buf.mode = "NORMAL"
    buf.cx = buf.clamp(buf.cx - 1, 1, #buf.buffer[buf.cy])
end

insertBindings["j"] = function(buf)
    if buf.waitForjk then
        buf.cx = buf.cx + 1
    end
    buf.waitForjk = true
    buf.jkTimer = 0

    buf.blocked_chars["j"] = true
    local line = buf.buffer[buf.cy]
    local a = line:sub(1, buf.cx - 1)
    local b = line:sub(buf.cx)
    buf.buffer[buf.cy] = a .. "j" .. b
end

return insertBindings
