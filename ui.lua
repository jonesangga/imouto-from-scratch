-- Consists of Button, Menu, Radio, and Dialogue class.

local game = require("game")

local ui = {}

-- Button class.
-- A button can only contain one line of text.
-- Button width and height cannot be set manually.

local Button = {}
Button.__index = Button
ui.Button = Button

function Button.new(x, y, text, onClick)
    return setmetatable({
        x = x, y = y,
        w       = game.font:getWidth(text) + 2 * game.PADDING,
        h       = game.font_height + 2 * game.PADDING,
        text    = text,
        onClick = onClick,
        padding = game.PADDING,
        hovered = false,
        pressed = false,
        enabled = true,
    }, Button)
end

function Button:contains(mx, my)
    return mx >= self.x and
           mx <= self.x + self.w and
           my >= self.y and
           my <= self.y + self.h
end

function Button:update(dt)
    local mx, my = love.mouse.getPosition()
    self.hovered = self:contains(mx, my)
end

function Button:draw()
    local bg = {0.2, 0.2, 0.2}
    if not self.enabled then
        bg = {0.5, 0.5, 0.5}
    elseif self.pressed then
        bg = {0.05, 0.6, 0.9}
    elseif self.hovered then
        bg = {0.1, 0.5, 0.8}
    end

    love.graphics.setColor(bg)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    -- -- border
    -- love.graphics.setColor(1, 1, 0)
    -- love.graphics.setLineWidth(2)
    -- love.graphics.rectangle("line", self.x, self.y, self.w - 1, self.h - 1)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.text, self.x + self.padding, self.y + self.padding)
end

function Button:mousepressed(mx, my, button)
    if not self.enabled then
        return
    end
    if button == 1 and self:contains(mx, my) then
        self.pressed = true
    end
end

function Button:mousereleased(mx, my, button)
    if not self.enabled then
        return
    end
    if button == 1 and self.pressed then
        if self:contains(mx, my) then
            self.onClick()
        end
        self.pressed = false
    end
end


-- Menu class. A wrapper for Button class.
-- Currently menu width and height cannot be specified.
-- For simplicity all buttons in menu cannot be disabled.
-- TODO: Support overflow: hidden.

local Menu = {}
Menu.__index = Menu
ui.Menu = Menu

-- TODO: For right align, it computes the width which also computed in Button.new().
--       Should it just passed the width and height?
function Menu.new(x, y, align, entries)
    local buttons = {}
    local button = nil
    for i, entry in ipairs(entries) do
        if align == "left" then
            button = Button.new(x, y, entry[1], entry[2])
        elseif align == "right" then
            button = Button.new(x - game.font:getWidth(entry[1]) - 2 * game.PADDING, y, entry[1], entry[2])
        end
        table.insert(buttons, button)
        y = button.y + button.h + 5 
    end

    return setmetatable({
        buttons = buttons,
    }, Menu)
end

function Menu:update()
    for _, button in ipairs(self.buttons) do
        button:update()
    end
end

function Menu:draw()
    for _, button in ipairs(self.buttons) do
        button:draw()
    end
end

function Menu:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:mousepressed(x, y, button)
    end
end

function Menu:mousereleased(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:mousereleased(x, y, button)
    end
end


-- Radio class. Similar to Menu class. A wrapper for Button class.
local Radio = {}
Radio.__index = Radio
ui.Radio = Radio

-- TODO: For right align, it computes the width which also computed in Button.new().
--       Should it just passed the width and height?
function Radio.new(x, y, align, entries)
    local buttons = {}
    local button = nil
    for i, entry in ipairs(entries) do
        if align == "left" then
            button = Button.new(x, y, entry[1], entry[2])
        elseif align == "right" then
            button = Button.new(x - game.font:getWidth(entry[1]) - 2 * game.PADDING, y, entry[1], entry[2])
        end
        table.insert(buttons, button)
        y = button.y + button.h + 5
    end

    return setmetatable({
        buttons = buttons,
        selected = 1,
    }, Radio)
end

function Radio:select(n)
    self.selected = n
end

function Radio:update()
    for _, button in ipairs(self.buttons) do
        button:update()
    end
end

function Radio:draw()
    for i, btn in ipairs(self.buttons) do
        local bg = {0.2, 0.2, 0.2}
        if not btn.enabled then
            bg = {0.5, 0.5, 0.5}
        elseif btn.hovered then
            bg = {0.1, 0.5, 0.8}
        end
        if i == self.selected then
            bg = {0.1, 0.1, 0.9}
        end

        love.graphics.setColor(bg)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(btn.text, btn.x + btn.padding, btn.y + btn.padding)
    end
end

function Radio:mousepressed(x, y, button)
    for i, btn in ipairs(self.buttons) do
        if not btn.enabled then
            return
        end
        if button == 1 and btn:contains(x, y) then
            btn.onClick()
            self.selected = i
        end
    end
end

function Radio:mousereleased(x, y, button)
end


-- Dialogue class.
-- TODO: Add sound effect when clicking dialogue box.

local Dialogue = {}
Dialogue.__index = Dialogue
ui.Dialogue = Dialogue

function Dialogue.new(lines)
    return setmetatable({
        -- These are fixed.
        x = 20, y = 360, w = 600, h = 100,
        lines = lines,
        speed = 20,

        -- These are updated.
        current   = 1,
        revealed  = 0,
        displayed = "",
        elapsed   = 0,
        finished  = false,
    }, Dialogue)
end

function Dialogue:reset()
    self.current   = 1
    self.revealed  = 0
    self.displayed = ""
    self.elapsed   = 0
    self.finished  = false
end

function Dialogue:update(dt)
    if self.finished then
        return
    end

    local text       = self.lines[self.current + 1]
    local textLength = #text
    self.elapsed     = self.elapsed + dt * self.speed

    -- While loop lets multiple characters be consumed if dt large.
    while self.elapsed >= 1 and self.revealed <= textLength do
        local ch       = text:sub(self.revealed, self.revealed)
        self.displayed = self.displayed .. ch
        self.revealed  = self.revealed + 1
        self.elapsed   = self.elapsed - 1
    end
    if self.revealed > textLength then
        self.finished = true
    end
end

function Dialogue:draw()
    -- Box for speaker name.
    love.graphics.rectangle("fill", self.x, self.y - game.font_height - 5, 60, game.font_height)
    -- Box for the text.
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    love.graphics.setColor(0, 0, 0)
    local n = self.lines[self.current]
    local name = nil
    if n == 1 then
        name = "Ada"
    elseif n == 2 then
        name = "You"
    else
        name = "..."
    end

    love.graphics.print(name, self.x, self.y - game.font_height - 5)
    love.graphics.printf(self.displayed, self.x, self.y, self.w)
end

function Dialogue:mousepressed(mx, my, button)
    if mx >= self.x and
        mx <= self.x + self.w and
        my >= self.y and
        my <= self.y + self.h then

        if self.finished then
            if self.current < #self.lines - 1 then
                self.current   = self.current + 2
                self.revealed  = 0
                self.displayed = ""
                self.elapsed   = 0
                self.finished  = false
            end
        else
            self.displayed = self.lines[self.current + 1]
            self.finished = true
        end
    end
end


return ui
