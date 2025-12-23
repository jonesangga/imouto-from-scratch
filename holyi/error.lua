local Error = {
    __tostring = function(s)
        return s.type .. ": " .. s.msg
    end
}
Error.__index = Error

-- TODO: Add line number.
function Error.new(type, msg)
    local t = {
        type = type,
        msg  = msg,
    }
    return setmetatable(t, Error)
end

local function LexerError(msg)
    local e = Error.new("LexerError", msg)
    error(e, 0)
end

local function ParserError(msg)
    local e = Error.new("ParserError", msg)
    error(e, 0)
end

return {
    LexerError  = LexerError,
    ParserError = ParserError,
}
