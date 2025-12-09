local game   = require("game")
local fsm    = require("fsm")
local imoscm = require("imoscheme.main-ifs")

local CAT_MAX_BYTES = 20 * 1024     -- Limit file size to avoid huge prints (20 KB).

local imoterm = {
    name = "imoterm",
}

local mode = "NORMAL"        -- NORMAL, IMOSCM.
local lines = {}
local max_lines = 100
local scroll = 0          -- lines scrolled up from bottom (0 = at bottom)
local input = ""          -- Current input buffer.
local prompt = "$ "
local history = {}
local hist_index = 0
local last_output = ""    -- For handling program that doesn't write newline at the end.
local builtins = {}

local cwd = "Ada"
local line_height = nil
local maxLinesVisible = 21

local function push_line(text)
    table.insert(lines, text)
    if #lines > max_lines then
        table.remove(lines, 1)
    end
end

local function write(text)
    if text:match("\n$") then
        push_line(last_output)
        last_output = ""
    else
        last_output = last_output .. text
    end
end

-- Built-in commands.

builtins.cat = function(args)
    if #args == 0 then
        push_line("Usage: cat [filename]")
        return
    end

    local path = cwd .. '/' .. args[1]

    local fp, err = io.open(path, "rb")
    if not fp then
        push_line("Error opening file: " .. tostring(err))
        return
    end

    local size = fp:seek("end")
    fp:seek("set")
    if size > CAT_MAX_BYTES then
        push_line("Error: file too large (" .. size .. " bytes)")
        return
    end

    local contents = fp:read("*a")
    fp:close()

    if not contents then
        push_line("Error reading file: " .. tostring(err))
        return
    end

    -- Split contents into lines and push each (preserve empty lines).
    -- TODO: Handle file without newline at the end.
    for line in contents:gmatch("(.-)\r?\n") do
        push_line(line)
    end
end

builtins.clear = function(args)
    lines = {}
    scroll = 0
    last_output = ""
end

builtins.echo = function(args)
    push_line(table.concat(args, " "))
end

builtins.help = function(args)
    if #args == 0 then
        push_line("ImoTerm. Type 'help name' for specific help. Available commands:")
        push_line("  cat [file]")
        push_line("  clear")
        push_line("  echo [arg ...]")
        push_line("  help [cmd]")
        push_line("  imoscm [file]")
        push_line("  pwd")
    elseif #args == 1 then
        local cmd = args[1]
        if cmd == "imoscm" then
            push_line("help: imoscm [file]")
            push_line("  Run imoscm program.")
        elseif cmd == "cat" then
            push_line("help: cat [file]")
            push_line("  Display content of file.")
        elseif cmd == "help" then
            push_line("help: help [cmd]")
            push_line("  Display information about builtin command.")
        elseif cmd == "pwd" then
            push_line("help: pwd")
            push_line("  Print name of current directory.")
        else
            push_line("help: no help for " .. cmd)
        end
    else
        push_line("help: too much args. See 'help help'.")
    end
end

builtins.imoscm = function(args)
    if #args == 0 then
        mode = "IMOSCM"
        prompt = "> "
        imoscm.prepare_repl()
    elseif #args == 1 then
        local path = cwd .. '/' .. args[1]
        imoscm.run_file(path)
    end
end

builtins.pwd = function(args)
    if #args == 0 then
        push_line(cwd)
    else
        push_line("pwd: too much args. See 'help pwd'.")
    end
end

local function imoscm_repl(line)
    print(line)
    imoscm.line(line)
end

local function execute(cmdline)
    push_line(last_output .. prompt .. cmdline)
    last_output = ""
    if mode == "IMOSCM" then
        imoscm_repl(cmdline)
        return
    end
    if cmdline:match("^%s*$") then return end
    table.insert(history, cmdline)
    hist_index = 0

    -- Simple parse: split by spaces.
    local parts = {}
    for word in cmdline:gmatch("%S+") do
        table.insert(parts, word)
    end
    local cmd = parts[1]:lower()
    local args = {}
    for i = 2, #parts do
        table.insert(args, parts[i])
    end

    if builtins[cmd] then
        builtins[cmd](args)
    else
        push_line("Unknown command: " .. cmd)
    end

end

function imoterm.enter()
    print("[imoterm] enter")
    love.graphics.setFont(game.fontMono)
    line_height = game.fontMonoHeight
    push_line("ImoTerm. Type 'help' for commands.")
    imoscm.setup(write, push_line)
end

function imoterm.exit()
    love.graphics.setFont(game.font)
    print("[imoterm] exit")
end

function imoterm.update(dt)
end

function imoterm.draw()
    love.graphics.clear(0.93, 0.93, 0.93)
    love.graphics.setColor(0, 0, 0)

    local w, h = love.graphics.getDimensions()

    local totalLines = #lines
    local bottomIndex = math.max(0, totalLines - scroll) -- index after the last printed line (0..totalLines)
    local startIndex = math.max(1, bottomIndex - maxLinesVisible + 1)
    local endIndex = bottomIndex

    local y = 0
    for i = startIndex, endIndex do
        love.graphics.print(lines[i], margin, y)
        y = y + line_height
    end

    -- Draw input prompt right after last output line (y currently is next line).
    local displayed = last_output .. prompt .. input
    love.graphics.print(displayed, margin, y)

    -- Cursor.
    local cursorX = game.fontMono:getWidth(displayed)
    love.graphics.rectangle("fill", cursorX, y, 10, line_height)
end

function imoterm.textinput(t)
    input = input .. t
end

function imoterm.keypressed(key)
    if key == "backspace" then
        -- remove last UTF-8 char
        -- simple byte-safe approach for ASCII (works for most)
        input = input:sub(1, -2)
    elseif key == "return" or key == "kpenter" then
        execute(input)
        input = ""
    elseif key == "up" then
        if #history > 0 then
            if hist_index == 0 then
                hist_index = #history
            else
                hist_index = math.max(1, hist_index - 1)
            end
            input = history[hist_index] or ""
        end
    elseif key == "down" then
        if #history > 0 and hist_index > 0 then
            hist_index = hist_index + 1
            if hist_index > #history then
                hist_index = 0
                input = ""
            else
                input = history[hist_index] or ""
            end
        end
    elseif key == "tab" then
        -- Basic tab completion for builtins.
        for name, _ in pairs(builtins) do
            if name:sub(1, #input) == input then
                input = name .. " "
                break
            end
        end
    elseif key == "escape" then
        fsm.pop()
    elseif key == "d" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        if mode == "IMOSCM" then
            push_line("")
            mode = "NORMAL"
            prompt = "$ "
            input = ""
        end
    end
end

function imoterm.mousepressed(x, y, button)
end

function imoterm.mousereleased(x, y, button)
end

return imoterm
