local game = require("game")

local vimouto = {
    name = "vimouto",
}

local fontW, fontH

local pwd = "Ada"           -- Ada's home dir.
local savePath = ""
local mode = "NORMAL"       -- "NORMAL" or "INSERT".
local buffer = {""}
local cmdbuf = ""
local cmdcx = 1
local cx, cy = 1, 1         -- Cursor column and row (1-based).
local row = 22
local scroll_y = 1

local bindings = {}
local pendings = {}
local remembercx = false
local cxBeforeMoveLine = 1

local blocked_chars = {}    -- Key that has been consumed in keypressed and will not be used in textinput.
                            -- NOTE: Handle enter with "\n" and space with " " later.


local function clamp(n, a, b)
    return math.max(a, math.min(b, n))
end

-- Move cursor to ensure valid column.
local function clampCursor()
    cx = clamp(cxBeforeMoveLine, 1, #buffer[cy])
end

local function saveToFile(path)
    local fp, err
    if not path or path == "" then
        if savePath == "" then
            error("No file name")
            return false
        end
        fp, err = io.open(savePath, "w")
    else
        path = "Ada/" .. path
        fp, err = io.open(path, "w")
    end

    if not fp then
        return false, err
    end
    savePath = path

    fp:write(table.concat(buffer, "\n"))
    fp:close()
    return true
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

bindings["d"] = function()
    cmdbuf = "d"
    remembercx = false
end

pendings["d"] = {
    ["d"] = function()
        delete_line(cy)
        cmdbuf = ""
    end,
}

bindings["g"] = function()
    cmdbuf = "g"
    remembercx = false
end

pendings["g"] = {
    ["g"] =  function()
        cy = 1
        cx = 1
    end,
}

bindings["j"] = function()
    cy = clamp(cy + 1, 1, #buffer)
    if not remembercx then
        remembercx = true
        cxBeforeMoveLine = cx
    end
    clampCursor()
end
bindings["down"] = bindings["j"]

bindings["k"] = function()
    cy = clamp(cy - 1, 1, #buffer)
    if not remembercx then
        remembercx = true
        cxBeforeMoveLine = cx
    end
    clampCursor()
end
bindings["up"] = bindings["k"]

bindings["h"] = function()
    cx = clamp(cx - 1, 1, #buffer[cy])
    remembercx = false
end
bindings["left"] = bindings["h"]

bindings["l"] = function()
    cx = clamp(cx + 1, 1, #buffer[cy])
    remembercx = false
end
bindings["right"] = bindings["l"]

bindings["i"] = function()
    if love.keyboard.isDown("lshift", "rshift") then
        blocked_chars["I"] = true
        cx = 1
    else
        blocked_chars["i"] = true
    end
    mode = "INSERT"
    remembercx = false
end

bindings["a"] = function()
    if love.keyboard.isDown("lshift", "rshift") then
        blocked_chars["A"] = true
        if cx > 1 then
            cx = #buffer[cy] + 1
        end
    else
        blocked_chars["a"] = true
        if cx > 1 then
            cx = cx + 1
        end
    end
    mode = "INSERT"
    remembercx = false
end

bindings["o"] = function()
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
end

bindings["x"] = function()
    local line = buffer[cy]
    local lineLen = #line
    buffer[cy] = line:sub(1, cx - 1) .. line:sub(cx + 1)
    if cx == lineLen and lineLen ~= 1 then
        cx = cx - 1
    end
    remembercx = false
end

bindings["0"] = function()
    cx = 1
    remembercx = false
end

bindings["4"] = function()
    if love.keyboard.isDown("lshift", "rshift") then
        cx = #buffer[cy]
    end
    remembercx = false
end

bindings[";"] = function()
    if love.keyboard.isDown("lshift", "rshift") then
        blocked_chars[":"] = true
        mode = "CMD"
        cmdbuf = ""
    end
end

bindings["backspace"] = function()
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
    love.graphics.print(cy .. "," .. cx, 500, (row - 1) * fontH)

    -- Small hint when normal's cmdbuf set.
    if mode == "NORMAL" and cmdbuf ~= "" then
        love.graphics.print(cmdbuf, 400, (row - 1) * fontH)
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
        local line = buffer[cy]
        local a = line:sub(1, cx - 1)
        local b = line:sub(cx)
        buffer[cy] = a .. t .. b
        cx = cx + #t
    elseif mode == "CMD" then
        cmdbuf = cmdbuf .. t
        cmdcx = cmdcx + #t
    end
end

function vimouto.keypressed(key, scancode, isrepeat)
    if mode == "INSERT" then
        if key == "backspace" then
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
        elseif key == "return" or key == "kpenter" then
            local line = buffer[cy]
            local a = line:sub(1, cx - 1)
            local b = line:sub(cx)
            buffer[cy] = a
            table.insert(buffer, cy + 1, b)
            cy = cy + 1
            cx = 1
        elseif key == "escape" then
            mode = "NORMAL"
            cx = clamp(cx - 1, 1, #buffer[cy])
        end
    elseif mode == "NORMAL" then  -- NORMAL mode.
        if cmdbuf ~= "" then
            if pendings[cmdbuf] and pendings[cmdbuf][key] then
                pendings[cmdbuf][key]()
            end
            cmdbuf = ""
            return
        end

        if bindings[key] then
            bindings[key]()
            return
        end
    else  -- "CMD" mode.
        if key == "backspace" then
            if cmdcx > 1 then
                cmdbuf = cmdbuf:sub(1, cmdcx - 2) .. cmdbuf:sub(cmdcx)
                cmdcx = cmdcx - 1
            else
                mode = "NORMAL"
                cmdbuf = ""
                cmdcx = 1
            end
        elseif key == "return" or key == "kpenter" then
            -- TODO: Add feedback message.
            local cmd, arg = cmdbuf:match("^([A-Za-z0-9]+)%s+([%w%-%._]+)%s*$")
            if cmd == nil then
                cmd = cmdbuf:match("^([A-Za-z0-9]+)$")
            end
            print(cmd, arg)

            if cmd == "q" and arg == nil then
                love.event.quit()
            elseif cmd == "w" then
                local ok, err = saveToFile(arg)
                print(ok, err)
            else
                print("Not a valid command: " .. cmd)
            end

            mode = "NORMAL"
            cmdbuf = ""
            cmdcx = 1
        elseif key == "escape" then
            mode = "NORMAL"
            cmdbuf = ""
            cmdcx = 1
        end
    end
end

function vimouto.mousepressed(x, y, button)
end

function vimouto.mousereleased(x, y, button)
end

return vimouto
