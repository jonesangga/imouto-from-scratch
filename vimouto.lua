local game = require("game")

local vimouto = {
    name = "vimouto",
}

local fontW, fontH

local mode = "NORMAL"       -- "NORMAL" or "INSERT".
local buffer = {""}
local cx, cy = 1, 1         -- Cursor column and row (1-based).
local row = 22

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
end

function vimouto.draw()
    love.graphics.clear(0.93, 0.93, 0.93)
    love.graphics.setColor(0, 0, 0)

    for i = 1, #buffer do
        love.graphics.print(buffer[i], 0, (i - 1) * fontH)
    end

    -- Draw mode, row, and col indicator.
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("-- " .. mode .. " --", 0, (row - 1) * fontH)
    love.graphics.print(cy .. "," .. cx, 500, (row - 1) * fontH)

    -- Draw cursor block (invert the color).
    local line = buffer[cy]
    local px = (cx - 1) * fontW
    local py = (cy - 1) * fontH
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", px, py, fontW, fontH)
    love.graphics.setColor(1, 1, 1)
    local chstr = line:sub(cx, cx) ~= "" and line:sub(cx, cx) or " "
    love.graphics.print(chstr, px, py)
end

function vimouto.textinput(t)
    if mode ~= "INSERT" then
        return
    end

    if blocked_chars[t] then
        return
    end

    local line = buffer[cy]
    local a = line:sub(1, cx - 1)
    local b = line:sub(cx)
    buffer[cy] = a .. t .. b
    cx = cx + #t
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
    else  -- NORMAL mode.
        if key == "h" or key == "left" then
            remembercx = false
            cx = clamp(cx - 1, 1, #buffer[cy])
        elseif key == "l" or key == "right" then
            remembercx = false
            cx = clamp(cx + 1, 1, #buffer[cy])
        elseif key == "j" or key == "down" then
            cy = clamp(cy + 1, 1, #buffer)
            if not remembercx then
                remembercx = true
                cxBeforeMoveLine = cx
            end
            clampCursor()
        elseif key == "k" or key == "up" then
            cy = clamp(cy - 1, 1, #buffer)
            if not remembercx then
                remembercx = true
                cxBeforeMoveLine = cx
            end
            clampCursor()
        elseif key == "i" then
            if love.keyboard.isDown("lshift", "rshift") then
                blocked_chars["I"] = true
                cx = 1
            else
                blocked_chars["i"] = true
            end
            mode = "INSERT"
        elseif key == "o" then
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
        elseif key == "a" then
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
        elseif key == "0" then
            cx = 1
        elseif key == "4" and love.keyboard.isDown("lshift", "rshift") then  -- "$".
            cx = #buffer[cy]
        elseif key == "x" then
            local line = buffer[cy]
            local lineLen = #line
            buffer[cy] = line:sub(1, cx - 1) .. line:sub(cx + 1)
            if cx == lineLen and lineLen ~= 1 then
                cx = cx - 1
            end
        end
    end
end

function vimouto.mousepressed(x, y, button)
end

function vimouto.mousereleased(x, y, button)
end

return vimouto
