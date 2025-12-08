local game   = require("game")
local fsm    = require("fsm")
local imoscm = require("imoscheme.main-ifs")

local imoterm = {
    name = "imoterm",
}
imoterm.line_height = nil
imoterm.lines = {}
imoterm.scroll = 0          -- lines scrolled up from bottom (0 = at bottom)
imoterm.input = ""          -- Current input buffer.
imoterm.history = {}
imoterm.hist_index = 0
imoterm.prompt = "> "
imoterm.max_lines = 100
imoterm.last_output = ""    -- For handling program that doesn't write newline at the end.
imoterm.builtins = {}

local maxLinesVisible = 21
local cwd = "Ada"

local function push_line(text)
    table.insert(imoterm.lines, text)
    if #imoterm.lines > imoterm.max_lines then
        table.remove(imoterm.lines, 1)
    end
end

local function write(text)
    if text:match("\n$") then
        push_line(imoterm.last_output)
        imoterm.last_output = ""
    else
        imoterm.last_output = imoterm.last_output .. text
    end
end

-- Built-in commands.

imoterm.builtins.cat = function(args)
    if #args == 0 then
        push_line("Usage: cat <filename>")
        return
    end
    local path = args[1]
    -- limit file size to avoid huge prints (e.g., 200 KB)
    local maxbytes = 20 * 1024
    if not love.filesystem then
        push_line("Error: love.filesystem not available")
        return
    end
    -- try love.filesystem (works in bundled LÖVE); fall back to io.open
    local contents, err
    if love.filesystem.getInfo and love.filesystem.getInfo(path) then
        local info = love.filesystem.getInfo(path)
        if info.size and info.size > maxbytes then
            push_line("Error: file too large (" .. info.size .. " bytes)")
            return
        end
        contents, err = love.filesystem.read(path)
    else
        local f, ferr = io.open(path, "rb")
        if not f then
            push_line("Error opening file: " .. tostring(ferr))
            return
        end
        contents = f:read("*a")
        f:close()
        if #contents > maxbytes then
            push_line("Error: file too large (" .. #contents .. " bytes)")
            return
        end
    end

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

imoterm.builtins.clear = function(args)
    imoterm.lines = {}
    imoterm.scroll = 0
    imoterm.last_output = ""
end

imoterm.builtins.echo = function(args)
    push_line(table.concat(args, " "))
end

imoterm.builtins.help = function(args)
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

imoterm.builtins.imoscm = function(args)
    local old_write = io.write
    io.write = write
    imoscm.run_file(args[1])
    io.write = old_write
end

imoterm.builtins.pwd = function(args)
    if #args == 0 then
        push_line(cwd)
    else
        push_line("pwd: too much args. See 'help pwd'.")
    end
end


local function execute(cmdline)
    push_line(imoterm.last_output .. imoterm.prompt .. cmdline)
    imoterm.last_output = ""
    if cmdline:match("^%s*$") then return end
    table.insert(imoterm.history, cmdline)
    imoterm.hist_index = 0

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

    if imoterm.builtins[cmd] then
        imoterm.builtins[cmd](args)
    else
        push_line("Unknown command: " .. cmd)
    end

end

function imoterm.enter()
    print("[imoterm] enter")
    love.graphics.setFont(game.fontMono)
    imoterm.line_height = game.fontMonoHeight
    push_line("ImoTerm. Type 'help' for commands.")
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

    local totalLines = #imoterm.lines
    local bottomIndex = math.max(0, totalLines - imoterm.scroll) -- index after the last printed line (0..totalLines)
    local startIndex = math.max(1, bottomIndex - maxLinesVisible + 1)
    local endIndex = bottomIndex

    local y = 0
    for i = startIndex, endIndex do
        love.graphics.print(imoterm.lines[i], margin, y)
        y = y + imoterm.line_height
    end

    -- Draw input prompt right after last output line (y currently is next line).
    local displayed = imoterm.last_output .. imoterm.prompt .. imoterm.input
    love.graphics.print(displayed, margin, y)

    -- Cursor.
    local cursorX = game.fontMono:getWidth(displayed)
    love.graphics.rectangle("fill", cursorX, y, 10, imoterm.line_height)
end

function imoterm.textinput(t)
    imoterm.input = imoterm.input .. t
end

function imoterm.keypressed(key)
    if key == "backspace" then
        -- remove last UTF-8 char
        -- simple byte-safe approach for ASCII (works for most)
        imoterm.input = imoterm.input:sub(1, -2)
    elseif key == "return" or key == "kpenter" then
        execute(imoterm.input)
        imoterm.input = ""
    elseif key == "up" then
        if #imoterm.history > 0 then
            if imoterm.hist_index == 0 then
                imoterm.hist_index = #imoterm.history
            else
                imoterm.hist_index = math.max(1, imoterm.hist_index - 1)
            end
            imoterm.input = imoterm.history[imoterm.hist_index] or ""
        end
    elseif key == "down" then
        if #imoterm.history > 0 and imoterm.hist_index > 0 then
            imoterm.hist_index = imoterm.hist_index + 1
            if imoterm.hist_index > #imoterm.history then
                imoterm.hist_index = 0
                imoterm.input = ""
            else
                imoterm.input = imoterm.history[imoterm.hist_index] or ""
            end
        end
    elseif key == "tab" then
        -- Basic tab completion for builtins.
        for name, _ in pairs(imoterm.builtins) do
            if name:sub(1, #imoterm.input) == imoterm.input then
                imoterm.input = name .. " "
                break
            end
        end
    elseif key == "escape" then
        fsm.pop()
    end
end

function imoterm.mousepressed(x, y, button)
end

function imoterm.mousereleased(x, y, button)
end

return imoterm
