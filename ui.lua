-- Consists of Button and Menu class.

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
        w       = game.font:getWidth(text) + 2 * game.padding,
        h       = game.fontHeight + 2 * game.padding,
        text    = text,
        onClick = onClick,
        padding = game.padding,
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
        bg = {0.15, 0.15, 0.15}
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

function Menu.new(x, y, entries)
    local buttons = {}
    for i, entry in ipairs(entries) do
        local button = Button.new(x, y, entry[1], entry[2])
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


return ui
