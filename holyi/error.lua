local Error = {
    __tostring = function(s)
        local text = s.type .. ": " .. s.msg
        if s.line then
            text = text .. "\n    at line " .. s.line
        end
        return text
    end
}
Error.__index = Error

-- TODO: Add line number.
function Error.new(type, msg, line)
    local t = {
        type = type,
        msg  = msg,
        line = line,
    }
    return setmetatable(t, Error)
end

local function LexerError(msg, line)
    local e = Error.new("LexerError", msg, line)
    error(e, 0)
end

local function ParserError(msg)
    local e = Error.new("ParserError", msg)
    error(e, 0)
end

local function TypeCheckError(msg)
    local e = Error.new("TypeCheckError", msg)
    error(e, 0)
end

return {
    LexerError     = LexerError,
    ParserError    = ParserError,
    TypeCheckError = TypeCheckError,
}
