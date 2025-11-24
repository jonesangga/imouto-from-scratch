local game = require("game")

local vimouto = {
    name = "vimouto",
}

local fontW, fontH

local pwd = "Ada"           -- Ada's home dir.
local changed = false
local savePath = ""
local mode = "NORMAL"       -- "NORMAL" or "INSERT".
local buffer = {""}
local cmdbuf = ""
local cmdcx = 1
local cx, cy = 1, 1         -- Cursor column and row (1-based).
local row = 22
local scroll_y = 1
local waitForjk = false
local jkTimer = 0           -- Using jk as escape.
local jkTimeout = 0.5       -- If over 1 second then it is just text input.

local normalBindings = {}
local insertBindings = {}
local cmdBindings = {}
local pendings = {}
local remembercx = false
local cxBeforeMoveLine = 1

local blocked_chars = {}    -- Key that has been consumed in keypressed and will not be used in textinput.
                            -- NOTE: Handle enter with "\n" and space with " " later.

local message = ""
local showMessage = false

local function clamp(n, a, b)
    return math.max(a, math.min(b, n))
end

-- Move cursor to ensure valid column.
local function clampCursor()
    cx = clamp(cxBeforeMoveLine, 1, #buffer[cy])
end

local function feedback(msg)
    showMessage = true
    message = msg
end

-- TODO: Fix later.
local function validatePath(path)
    return true
end

-- NOTE: Currently doesn't support directory path.
local function write(path)
    if not path or path == "" then
        if savePath == "" then
            feedback("ERROR: No file name")
            return
        end
    else
        if not validatePath(path) then
            feedback("ERROR: Invalid path")
            return
        end
        savePath = "Ada/" .. path
    end

    local fp, err = io.open(savePath, "w")
    if not fp then
        feedback("ERROR: Cannot open " .. savePath)
        return
    end

    fp:write(table.concat(buffer, "\n"))
    fp:close()
    feedback(savePath .. " written")
    changed = false
end

local function delete_line(r)
    if #buffer == 1 then
        buffer[1] = ""
        cx, cy = 1, 1
        return
    end
    table.remove(buffer, r)
    if cy > #buffer then
        cy = #buffer
    end
    cx = 1
end

normalBindings["d"] = function()
    cmdbuf = "d"
    remembercx = false
end

pendings["d"] = {
    ["d"] = function()
        delete_line(cy)
        cmdbuf = ""
    end,
}

normalBindings["g"] = function()
    if love.keyboard.isDown("lshift", "rshift") then
        cy = #buffer
        cx = 1
    else
        cmdbuf = "g"
    end
    remembercx = false
end

pendings["g"] = {
    ["g"] =  function()
        cy = 1
        cx = 1
    end,
}

normalBindings["j"] = function()
    cy = clamp(cy + 1, 1, #buffer)
    if not remembercx then
        remembercx = true
        cxBeforeMoveLine = cx
    end
    clampCursor()
end
normalBindings["down"] = normalBindings["j"]

normalBindings["k"] = function()
    cy = clamp(cy - 1, 1, #buffer)
    if not remembercx then
        remembercx = true
        cxBeforeMoveLine = cx
    end
    clampCursor()
end
normalBindings["up"] = normalBindings["k"]

normalBindings["h"] = function()
    cx = clamp(cx - 1, 1, #buffer[cy])
    remembercx = false
end
normalBindings["left"] = normalBindings["h"]

normalBindings["l"] = function()
    cx = clamp(cx + 1, 1, #buffer[cy])
    remembercx = false
end
normalBindings["right"] = normalBindings["l"]

normalBindings["i"] = function()
    if love.keyboard.isDown("lshift", "rshift") then
        blocked_chars["I"] = true
        cx = 1
    else
        blocked_chars["i"] = true
    end
    mode = "INSERT"
    remembercx = false
end

normalBindings["a"] = function()
    if love.keyboard.isDown("lshift", "rshift") then
        blocked_chars["A"] = true
        cx = #buffer[cy] + 1  -- NOTE: The case for empty line already included here.
    else
        blocked_chars["a"] = true
        if #buffer[cy] == 0 then
            cx = 1
        else
            cx = cx + 1
        end
    end
    mode = "INSERT"
    remembercx = false
end

normalBindings["o"] = function()
    if love.keyboard.isDown("lshift", "rshift") then
        blocked_chars["O"] = true
        table.insert(buffer, cy, "")
        cx = 1
    else
        blocked_chars["o"] = true
        table.insert(buffer, cy + 1, "")
        cy = cy + 1
        cx = 1
    end
    mode = "INSERT"
    remembercx = false
    changed = true
end

normalBindings["x"] = function()
    local line = buffer[cy]
    local lineLen = #line
    buffer[cy] = line:sub(1, cx - 1) .. line:sub(cx + 1)
    if cx == lineLen and lineLen ~= 1 then
        cx = cx - 1
    end
    remembercx = false
end

normalBindings["0"] = function()
    cx = 1
    remembercx = false
end

normalBindings["4"] = function()
    if love.keyboard.isDown("lshift", "rshift") then
        cx = #buffer[cy]
    end
    remembercx = false
end

normalBindings[";"] = function()
    if love.keyboard.isDown("lshift", "rshift") then
        blocked_chars[":"] = true
        mode = "CMD"
        cmdbuf = ""
        showMessage = false
    end
end

normalBindings["backspace"] = function()
    if cx > 1 then
        cx = cx - 1
    else
        -- Go to the end of previous line, if any.
        if cy > 1 then
            cy = cy - 1
            cx = #buffer[cy]
            -- Handle empty line.
            if cx == 0 then
                cx = 1
            end
        end
    end
    remembercx = false
end

insertBindings["backspace"] = function()
    local line = buffer[cy]
    if cx > 1 then
        buffer[cy] = line:sub(1, cx - 2) .. line:sub(cx)
        cx = cx - 1
    else
        -- Join with previous line if present.
        if cy > 1 then
            local prevlen = #buffer[cy - 1]
            buffer[cy - 1] = buffer[cy - 1] .. buffer[cy]
            table.remove(buffer, cy)
            cy = cy - 1
            cx = prevlen + 1
        end
    end
end

insertBindings["return"] = function()
    local line = buffer[cy]
    local a = line:sub(1, cx - 1)
    local b = line:sub(cx)
    buffer[cy] = a
    table.insert(buffer, cy + 1, b)
    cy = cy + 1
    cx = 1
end
insertBindings["kpenter"] = insertBindings["return"]

insertBindings["escape"] = function()
    mode = "NORMAL"
    cx = clamp(cx - 1, 1, #buffer[cy])
end

insertBindings["j"] = function()
    if waitForjk then
        cx = cx + 1
    end
    waitForjk = true
    jkTimer = 0

    blocked_chars["j"] = true
    local line = buffer[cy]
    local a = line:sub(1, cx - 1)
    local b = line:sub(cx)
    buffer[cy] = a .. "j" .. b
end

cmdBindings["backspace"] = function()
    if cmdcx > 1 then
        cmdbuf = cmdbuf:sub(1, cmdcx - 2) .. cmdbuf:sub(cmdcx)
        cmdcx = cmdcx - 1
    else
        mode = "NORMAL"
        cmdbuf = ""
        cmdcx = 1
    end
end

cmdBindings["return"] = function()
    local cmd, arg = cmdbuf:match("^([A-Za-z0-9]+)%s+([%w%-%._]+)%s*$")
    if cmd == nil then
        cmd = cmdbuf:match("^([A-Za-z0-9]+)$")
    end

    if cmd ~= nil then
        if cmd == "q" and arg == nil then
            love.event.quit()
        elseif cmd == "w" then
            write(arg)
        else
            feedback("ERROR: Not a valid command: " .. cmd)
        end
    else
        feedback("ERROR: Not a valid command")
    end

    mode = "NORMAL"
    cmdbuf = ""
    cmdcx = 1
end

cmdBindings["escape"] = function()
    mode = "NORMAL"
    cmdbuf = ""
    cmdcx = 1
end


function vimouto.enter()
    print("[vimouto] enter")
    love.graphics.setFont(game.fontMono)
    fontW = game.fontMonoWidth
    fontH = game.fontMonoHeight
end

function vimouto.exit()
    print("[vimouto] exit")
end

function vimouto.update(dt)
    blocked_chars = {}

    -- When scrolling, keep cursor within visible area.
    local lines_on_screen = row - 1
    if cy < scroll_y then
        scroll_y = cy
    elseif cy >= scroll_y + lines_on_screen then
        scroll_y = cy - lines_on_screen + 1
    end

    if waitForjk then
        jkTimer = jkTimer + dt
        if jkTimer > jkTimeout then
            waitForjk = false
            cx = cx + 1
        end
    end
end

function vimouto.draw()
    love.graphics.clear(0.93, 0.93, 0.93)
    love.graphics.setColor(0, 0, 0)

    local digitMax = math.floor(math.log10(#buffer)) + 1
    local lineNumberW = digitMax + 1

    local function format(n)
        local digit = math.floor(math.log10(n)) + 1
        return string.rep(" ", digitMax - digit) .. n .. " "
    end

    local to = math.min(scroll_y + row - 2, #buffer)
    for i = scroll_y, to do
        love.graphics.print(format(i) .. buffer[i], 0, (i - scroll_y) * fontH)
    end

    -- Draw mode, row, and col indicator.
    love.graphics.setColor(0, 0, 0)
    if mode == "INSERT" then
        love.graphics.print("-- INSERT --", 0, (row - 1) * fontH)
    elseif mode == "CMD" then
        love.graphics.print(":" .. cmdbuf, 0, (row - 1) * fontH)
    end

    if mode ~= "CMD" then
        if changed then
            love.graphics.print("+", 480, (row - 1) * fontH)
        end
        love.graphics.print(cy .. "," .. cx, 500, (row - 1) * fontH)
    end

    -- Small hint when normal's cmdbuf set.
    if mode == "NORMAL" and cmdbuf ~= "" then
        love.graphics.print(cmdbuf, 400, (row - 1) * fontH)
    end

    if showMessage then
        love.graphics.print(message, 0, (row - 1) * fontH)
    end

    -- Draw cursor block (invert the color).
    if mode == "CMD" then
        local px = cmdcx * fontW
        local py = (row - 1) * fontH
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", px, py, fontW, fontH)
        love.graphics.setColor(1, 1, 1)
        local chstr = cmdbuf:sub(cmdcx, cmdcx) ~= "" and cmdbuf:sub(cmdcx, cmdcx) or " "
        love.graphics.print(chstr, px, py)
    else
        local line = buffer[cy]
        local px = (cx - 1 + lineNumberW) * fontW
        local py = (cy - scroll_y) * fontH
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", px, py, fontW, fontH)
        love.graphics.setColor(1, 1, 1)
        local chstr = line:sub(cx, cx) ~= "" and line:sub(cx, cx) or " "
        love.graphics.print(chstr, px, py)
    end
end

function vimouto.textinput(t)
    if blocked_chars[t] then
        return
    end
    if mode == "INSERT" then
        if waitForjk then
            waitForjk = false

            if t == "k" then
                local line = buffer[cy]
                buffer[cy] = line:sub(1, cx - 1) .. line:sub(cx + 1)
                cx = clamp(cx - 1, 1, #buffer[cy])
                mode = "NORMAL"
                return
            end
            cx = cx + 1
        end

        local line = buffer[cy]
        local a = line:sub(1, cx - 1)
        local b = line:sub(cx)
        buffer[cy] = a .. t .. b
        cx = cx + #t
        changed = true
    elseif mode == "CMD" then
        cmdbuf = cmdbuf .. t
        cmdcx = cmdcx + #t
    end
end

function vimouto.keypressed(key, scancode, isrepeat)
    if mode == "INSERT" then
        if insertBindings[key] then
            insertBindings[key]()
            return
        end
    elseif mode == "NORMAL" then  -- NORMAL mode.
        if cmdbuf ~= "" then
            if pendings[cmdbuf] and pendings[cmdbuf][key] then
                pendings[cmdbuf][key]()
            end
            cmdbuf = ""
            return
        end

        if normalBindings[key] then
            normalBindings[key]()
            return
        end
    else  -- "CMD" mode.
        if cmdBindings[key] then
            cmdBindings[key]()
            return
        end
    end
end

function vimouto.mousepressed(x, y, button)
end

function vimouto.mousereleased(x, y, button)
end

return vimouto
