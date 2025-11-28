local game = require("game")

local Buffer = {}
Buffer.__index = Buffer

local currentId = 1

function Buffer.new(parent, name)
    local buf = setmetatable({}, Buffer)
    parent.buffers[name] = buf
    buf.id = currentId
    buf.parent = parent
    buf.cx = 1         -- Cursor column and row (1-based).
    buf.cy = 1
    buf.cmdcx = 1
    buf.scroll_x = 1
    buf.scroll_y = 1
    buf.changed = false
    buf.savePath = ""
    buf.lines = {""}
    buf.cmdbuf = ""
    buf.waitForjk = false
    buf.jkTimer = 0           -- Using jk as escape.
    buf.jkTimeout = 0.5       -- If over 1 second then it is just text input.
    buf.remembercx = false
    buf.cxBeforeMoveLine = 1

    buf.blocked_chars = {}    -- Key that has been consumed in keypressed and will not be used in textinput.
                                -- NOTE: Handle enter with "\n" and space with " " later.
    currentId = currentId + 1
    return buf
end

function Buffer.clamp(n, a, b)
    return math.max(a, math.min(b, n))
end

-- Move cursor to ensure valid column.
function Buffer:clampCursor()
    self.cx = self.clamp(self.cxBeforeMoveLine, 1, #self.lines[self.cy])
end

function Buffer:adjustView()
    if self.cx < self.scroll_x then
        self.scroll_x = self.cx
    elseif self.cx >= self.scroll_x + self.parent.cols_visible then
        self.scroll_x = self.cx - self.parent.cols_visible + 1
    end
end

function Buffer:calculateDigits()
    return math.floor(math.log10(#self.lines)) + 1
end

-- TODO: Fix later.
function Buffer.validatePath(path)
    return true
end

-- NOTE: Currently doesn't support directory path.
function Buffer:write(path)
    if not path or path == "" then
        if self.savePath == "" then
            self.parent:echoError("ERROR: No file name")
            return
        end
    else
        if not self.validatePath(path) then
            self.parent:echoError("ERROR: Invalid path")
            return
        end
        self.savePath = "Ada/" .. path
    end

    local fp, err = io.open(self.savePath, "w")
    if not fp then
        self.parent:echoError("ERROR: Cannot open " .. savePath)
        return
    end

    fp:write(table.concat(self.lines, "\n"))
    fp:close()
    self.parent:echo("\"" .. self.savePath .. "\" written")
    self.changed = false
end

function Buffer:delete_line(r)
    if #self.lines == 1 then
        self.lines[1] = ""
        self.cx, self.cy = 1, 1
        return
    end
    table.remove(self.lines, r)
    if self.cy > #self.lines then
        self.cy = #self.lines
    end
    self.cx = 1
end

return Buffer
