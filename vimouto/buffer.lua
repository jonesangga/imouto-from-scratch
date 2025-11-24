local game = require("game")
local cmd = require("vimouto/cmd_binding")
local insert = require("vimouto/insert_binding")
local normal = require("vimouto/normal_binding")

local row = 22

local Buffer = {}
Buffer.__index = Buffer

function Buffer.new(path)
    local buf = setmetatable({}, Buffer)
    buf.fontH = game.fontMonoHeight
    buf.fontW = game.fontMonoWidth
    buf.cx = 1         -- Cursor column and row (1-based).
    buf.cy = 1
    buf.cmdcx = 1
    buf.scroll_y = 1
    buf.changed = false
    buf.savePath = ""
    buf.mode = "NORMAL"       -- "NORMAL" or "INSERT".
    buf.lines = {""}
    buf.cmdbuf = ""
    buf.waitForjk = false
    buf.jkTimer = 0           -- Using jk as escape.
    buf.jkTimeout = 0.5       -- If over 1 second then it is just text input.
    buf.remembercx = false
    buf.cxBeforeMoveLine = 1

    buf.blocked_chars = {}    -- Key that has been consumed in keypressed and will not be used in textinput.
                                -- NOTE: Handle enter with "\n" and space with " " later.

    buf.message = ""
    buf.showMessage = false
    buf.feedbackError = false
    buf.cmdBindings = cmd
    buf.insertBindings = insert
    buf.normalBindings = normal
    buf.pendings = normal.pendings
    return buf
end

function Buffer.clamp(n, a, b)
    return math.max(a, math.min(b, n))
end

-- Move cursor to ensure valid column.
function Buffer:clampCursor()
    self.cx = self.clamp(self.cxBeforeMoveLine, 1, #self.lines[self.cy])
end

function Buffer:echo(msg)
    self.howMessage = true
    self.essage = msg
    self.eedbackError = false
end

function Buffer:echoError(msg)
    self.howMessage = true
    self.essage = msg
    self.eedbackError = true
end

-- TODO: Fix later.
function Buffer.validatePath(path)
    return true
end

-- NOTE: Currently doesn't support directory path.
function Buffer:write(path)
    if not path or path == "" then
        if self.savePath == "" then
            self:echoError("ERROR: No file name")
            return
        end
    else
        if not self.validatePath(path) then
            self:echoError("ERROR: Invalid path")
            return
        end
        self.savePath = "Ada/" .. path
    end

    local fp, err = io.open(self.savePath, "w")
    if not fp then
        self:echoError("ERROR: Cannot open " .. savePath)
        return
    end

    fp:write(table.concat(self.lines, "\n"))
    fp:close()
    self:echo("\"" .. self.savePath .. "\" written")
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

function Buffer:update(dt)
    self.blocked_chars = {}

    -- When scrolling, keep cursor within visible area.
    local lines_on_screen = row - 1
    if self.cy < self.scroll_y then
        self.scroll_y = self.cy
    elseif self.cy >= self.scroll_y + lines_on_screen then
        self.scroll_y = self.cy - lines_on_screen + 1
    end

    if self.waitForjk then
        self.jkTimer = self.jkTimer + dt
        if self.jkTimer > self.jkTimeout then
            self.waitForjk = false
            self.cx = self.cx + 1
        end
    end
end

function Buffer:draw()
    love.graphics.clear(0.93, 0.93, 0.93)
    love.graphics.setColor(0, 0, 0)

    local digitMax = math.floor(math.log10(#self.lines)) + 1
    local lineNumberW = digitMax + 1

    local function format(n)
        local digit = math.floor(math.log10(n)) + 1
        return string.rep(" ", digitMax - digit) .. n .. " "
    end

    local to = math.min(self.scroll_y + row - 2, #self.lines)
    for i = self.scroll_y, to do
        love.graphics.print(format(i) .. self.lines[i], 0, (i - self.scroll_y) * self.fontH)
    end

    -- Draw mode, row, and col indicator.
    love.graphics.setColor(0, 0, 0)
    if self.mode == "INSERT" then
        love.graphics.print("-- INSERT --", 0, (row - 1) * self.fontH)
    elseif self.mode == "CMD" then
        love.graphics.print(":" .. self.cmdbuf, 0, (row - 1) * self.fontH)
    end

    if self.mode ~= "CMD" then
        if self.changed then
            love.graphics.print("+", 480, (row - 1) * self.fontH)
        end
        love.graphics.print(self.cy .. "," .. self.cx, 500, (row - 1) * self.fontH)
    end

    -- Small hint when normal's cmdbuf set.
    if self.mode == "NORMAL" and self.cmdbuf ~= "" then
            love.graphics.print(self.cmdbuf, 400, (row - 1) * self.fontH)
    end

    if self.showMessage then
        if self.feedbackError then
            love.graphics.setColor(0.84, 0, 0)
            love.graphics.rectangle("fill", 0, (row - 1) * self.fontH, game.fontMono:getWidth(self.message), self.fontH)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(self.message, 0, (row - 1) * self.fontH)
        else
            love.graphics.print(self.message, 0, (row - 1) * self.fontH)
        end
    end

    -- Draw cursor block (invert the color).
    if self.mode == "CMD" then
        local px = self.cmdcx * self.fontW
        local py = (row - 1) * self.fontH
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", px, py, self.fontW, self.fontH)
        love.graphics.setColor(1, 1, 1)
        local chstr = self.cmdbuf:sub(self.cmdcx, self.cmdcx) ~= "" and self.cmdbuf:sub(self.cmdcx, self.cmdcx) or " "
        love.graphics.print(chstr, px, py)
    else
        local line = self.lines[self.cy]
        local px = (self.cx - 1 + lineNumberW) * self.fontW
        local py = (self.cy - self.scroll_y) * self.fontH
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", px, py, self.fontW, self.fontH)
        love.graphics.setColor(1, 1, 1)
        local chstr = line:sub(self.cx, self.cx) ~= "" and line:sub(self.cx, self.cx) or " "
        love.graphics.print(chstr, px, py)
    end
end

function Buffer:textinput(t)
    if self.blocked_chars[t] then
        return
    end

    if self.mode == "INSERT" then
        if self.waitForjk then
            self.waitForjk = false

            if t == "k" then
                local line = self.lines[self.cy]
                self.lines[self.cy] = line:sub(1, self.cx - 1) .. line:sub(self.cx + 1)
                self.cx = self.clamp(self.cx - 1, 1, #self.lines[self.cy])
                self.mode = "NORMAL"
                return
            end
            self.cx = self.cx + 1
        end

        local line = self.lines[self.cy]
        local a = line:sub(1, self.cx - 1)
        local b = line:sub(self.cx)
        self.lines[self.cy] = a .. t .. b
        self.cx = self.cx + #t
        self.changed = true
    elseif self.mode == "CMD" then
        self.cmdbuf = self.cmdbuf .. t
        self.cmdcx = self.cmdcx + #t
    end
end

function Buffer:keypressed(key)
    if self.mode == "INSERT" then
        if self.insertBindings[key] then
            self.insertBindings[key](self)
            return
        end
    elseif self.mode == "NORMAL" then  -- NORMAL mode.
        if self.cmdbuf ~= "" then
            if self.pendings[self.cmdbuf] and self.pendings[self.cmdbuf][key] then
                self.pendings[self.cmdbuf][key](self)
            end
            self.cmdbuf = ""
            return
        end

        if self.normalBindings[key] then
            self.normalBindings[key](self)
            return
        end
    else  -- "CMD" mode.
        if self.cmdBindings[key] then
            self.cmdBindings[key](self)
            return
        end
    end
end

return Buffer
