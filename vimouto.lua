local game = require("game")
local fsm = require("fsm")
local util = require("util")
local buffer = require("vimouto/buffer")
local tree = require("vimouto/tree")
local cmdBindings = require("vimouto/cmd_binding")
local insertBindings = require("vimouto/insert_binding")
local normalBindings = require("vimouto/normal_binding")
local treeBindings = require("vimouto/tree_binding")

local pendings = normalBindings.pendings

local vimouto = {
    name = "vimouto",
}
local active = nil
local row = 22

function vimouto:reset()
    self.fontH = game.fontMonoHeight
    self.fontW = game.fontMonoWidth
    self.showTree = false
    self.treeFocus = false
    self.tree = tree.new(vimouto)
    self.buffers = {}
    self.mode = "NORMAL"  -- "INSERT", "NORMAL", "CMD", "TREE".
    self.message = ""
    self.messageLine = 1
    self.showMessage = false
    self.feedbackError = false

    local buf = buffer.new(vimouto, "")
    self.active = buf
    active = buf
end

function vimouto.quit()
    fsm.pop()
end

function vimouto.loadTree()
    local files = util.getFileNames("Ada")
    vimouto.tree.lines = files
end

function vimouto.open(path)
    path = "Ada/" .. path
    if vimouto.buffers[path] then
        print("there already exist: " .. path)
        return
    end

    local fp, err = io.open(path, "r")
    if not fp then
        vimouto:echoError("ERROR: Cannot read \"" .. path .. "\"")
        return
    end

    local content = fp:read("*a")
    fp:close()
    local lines = util.splitLines(content)
    if #lines == 0 then
        lines = {""}
    end
    local buf = buffer.new(vimouto, path)
    buf.lines = lines
    buf.savePath = path
    vimouto.active = buf
    active = buf
end

function vimouto:echo(msg)
    self.showMessage = true
    self.message = msg
    self.messageLine = 1
    self.feedbackError = false
end

function vimouto:echoError(msg)
    self.showMessage = true
    self.message = msg
    self.messageLine = 1
    self.feedbackError = true
end

function vimouto:ls()
    self.showMessage = true
    self.messageLine = 1
    local msg = "------"
    for name, buf in pairs(vimouto.buffers) do
        msg = msg .. "\n" .. buf.id .. " \"" .. name .. "\""
        self.messageLine = self.messageLine + 1
    end
    self.message = msg
    self.feedbackError = false
end

function vimouto.enter()
    print("[vimouto] enter")
    love.graphics.setFont(game.fontMono)

    vimouto:reset()
    vimouto.loadTree()
end

function vimouto.exit()
    love.graphics.setFont(game.font)
    print("[vimouto] exit")
end

function vimouto.update(dt)
    active.blocked_chars = {}

    -- When scrolling, keep cursor within visible area.
    local lines_on_screen = row - 1
    if active.cy < active.scroll_y then
        active.scroll_y = active.cy
    elseif active.cy >= active.scroll_y + lines_on_screen then
        active.scroll_y = active.cy - lines_on_screen + 1
    end

    if active.waitForjk then
        active.jkTimer = active.jkTimer + dt
        if active.jkTimer > active.jkTimeout then
            active.waitForjk = false
            active.cx = active.cx + 1
        end
    end
end

function vimouto.draw()
    love.graphics.clear(0.93, 0.93, 0.93)
    love.graphics.setColor(0, 0, 0)

    local start = 0
    if vimouto.showTree then
        if vimouto.treeFocus then
            local px = start
            local py = (vimouto.tree.cy - vimouto.tree.scroll_y) * vimouto.fontH
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.rectangle("fill", px, py, vimouto.fontW * 20, vimouto.fontH)
        end

        love.graphics.setColor(0, 0, 0)

        local i = 1
        for _, file in pairs(vimouto.tree.lines) do
            love.graphics.print(file, start, (i - 1) * vimouto.fontH)
            i = i + 1
        end

        local separator = vimouto.fontW * 19

        -- Draw background to hide the overflow.
        love.graphics.setColor(0.93, 0.93, 0.93)
        love.graphics.rectangle("fill", separator, 0, vimouto.fontW * 45, (row - 1) * vimouto.fontH)

        love.graphics.setColor(0, 0, 0)
        for i = 1, 21 do
            love.graphics.print("|", separator, (i - 1) * vimouto.fontH)
        end
        start = vimouto.fontW * 20
    end

    local digitMax = math.floor(math.log10(#active.lines)) + 1
    local lineNumberW = digitMax + 1

    local function format(n)
        local digit = math.floor(math.log10(n)) + 1
        return string.rep(" ", digitMax - digit) .. n .. " "
    end

    local to = math.min(active.scroll_y + row - 2, #active.lines)
    for i = active.scroll_y, to do
        love.graphics.print(format(i) .. active.lines[i], start, (i - active.scroll_y) * vimouto.fontH)
    end

    -- Draw mode, row, and col indicator.
    love.graphics.setColor(0, 0, 0)
    if vimouto.mode == "INSERT" then
        love.graphics.print("-- INSERT --", 0, (row - 1) * vimouto.fontH)
    elseif vimouto.mode == "CMD" then
        love.graphics.print(":" .. active.cmdbuf, 0, (row - 1) * vimouto.fontH)
    end

    if vimouto.mode ~= "CMD" then
        if active.changed then
            love.graphics.print("+", 480, (row - 1) * vimouto.fontH)
        end
        love.graphics.print(active.cy .. "," .. active.cx, 500, (row - 1) * vimouto.fontH)
    end

    -- Small hint when normal's cmdbuf set.
    if vimouto.mode == "NORMAL" and active.cmdbuf ~= "" then
            love.graphics.print(active.cmdbuf, 400, (row - 1) * vimouto.fontH)
    end

    if vimouto.showMessage then
        if vimouto.feedbackError then
            love.graphics.setColor(0.84, 0, 0)
            love.graphics.rectangle("fill", 0, (row - 1) * vimouto.fontH, game.fontMono:getWidth(vimouto.message), vimouto.fontH)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(vimouto.message, 0, (row - 1) * vimouto.fontH)
        else
            love.graphics.print(vimouto.message, 0, (row - vimouto.messageLine) * vimouto.fontH)
        end
    end

    -- Draw cursor block (invert the color).
    if vimouto.mode == "CMD" then
        local px = active.cmdcx * vimouto.fontW
        local py = (row - 1) * vimouto.fontH
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", px, py, vimouto.fontW, vimouto.fontH)
        love.graphics.setColor(1, 1, 1)
        local chstr = active.cmdbuf:sub(active.cmdcx, active.cmdcx) ~= "" and active.cmdbuf:sub(active.cmdcx, active.cmdcx) or " "
        love.graphics.print(chstr, px, py)
    else
        if not vimouto.treeFocus then
            local line = active.lines[active.cy]
            local px = start + (active.cx - 1 + lineNumberW) * vimouto.fontW
            local py = (active.cy - active.scroll_y) * vimouto.fontH
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", px, py, vimouto.fontW, vimouto.fontH)
            love.graphics.setColor(1, 1, 1)
            local chstr = line:sub(active.cx, active.cx) ~= "" and line:sub(active.cx, active.cx) or " "
            love.graphics.print(chstr, px, py)
        end
    end
end

function vimouto.textinput(t)
    if active.blocked_chars[t] then
        return
    end

    if vimouto.mode == "INSERT" then
        if active.waitForjk then
            active.waitForjk = false

            if t == "k" then
                local line = active.lines[active.cy]
                active.lines[active.cy] = line:sub(1, active.cx - 1) .. line:sub(active.cx + 1)
                active.cx = active.clamp(active.cx - 1, 1, #active.lines[active.cy])
                vimouto.mode = "NORMAL"
                return
            end
            active.cx = active.cx + 1
        end

        local line = active.lines[active.cy]
        local a = line:sub(1, active.cx - 1)
        local b = line:sub(active.cx)
        active.lines[active.cy] = a .. t .. b
        active.cx = active.cx + #t
        active.changed = true
    elseif vimouto.mode == "CMD" then
        active.cmdbuf = active.cmdbuf .. t
        active.cmdcx = active.cmdcx + #t
    end
end

function vimouto.keypressed(key)
    if vimouto.mode == "INSERT" then
        if insertBindings[key] then
            insertBindings[key](active)
            return
        end
    elseif vimouto.mode == "NORMAL" then
        if active.cmdbuf ~= "" then
            if pendings[active.cmdbuf] and pendings[active.cmdbuf][key] then
                pendings[active.cmdbuf][key](active)
            end
            active.cmdbuf = ""
            return
        end

        if normalBindings[key] then
            normalBindings[key](active)
            return
        end
    elseif vimouto.mode == "CMD" then
        if cmdBindings[key] then
            cmdBindings[key](active)
            return
        end
    else
        if treeBindings[key] then
            treeBindings[key](vimouto.tree)
            return
        end
    end
end

function vimouto.mousepressed(x, y, button)
end

function vimouto.mousereleased(x, y, button)
end

return vimouto
