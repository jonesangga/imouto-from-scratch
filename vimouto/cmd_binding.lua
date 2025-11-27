local cmdBindings = {}

cmdBindings["backspace"] = function(buf)
    if buf.cmdcx > 1 then
        buf.cmdbuf = buf.cmdbuf:sub(1, buf.cmdcx - 2) .. buf.cmdbuf:sub(buf.cmdcx)
        buf.cmdcx = buf.cmdcx - 1
    else
        buf.parent.mode = "NORMAL"
        buf.cmdbuf = ""
        buf.cmdcx = 1
    end
end

cmdBindings["return"] = function(buf)
    local cmd, arg = buf.cmdbuf:match("^([A-Za-z0-9]+)%s+([%w%-%._]+)%s*$")
    if cmd == nil then
        cmd = buf.cmdbuf:match("^([A-Za-z0-9]+)$")
    end

    if cmd ~= nil then
        if cmd == "q" and arg == nil then
            love.event.quit()
        elseif cmd == "ls" then
            buf.parent:ls()
        elseif cmd == "w" then
            buf:write(arg)
        elseif cmd == "e" and arg ~= nil then
            buf.parent.open(arg)
        else
            buf.parent:echoError("ERROR: Not a valid command: " .. cmd)
        end
    else
        buf.parent:echoError("ERROR: Not a valid command")
    end

    buf.parent.mode = "NORMAL"
    buf.cmdbuf = ""
    buf.cmdcx = 1
end

cmdBindings["escape"] = function(buf)
    buf.parent.mode = "NORMAL"
    buf.cmdbuf = ""
    buf.cmdcx = 1
end

return cmdBindings
