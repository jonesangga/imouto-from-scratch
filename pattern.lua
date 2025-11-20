local fsm = require("fsm")
local ui = require("ui")
local util = require("util")

local pattern = {
    name = "Pattern",
}

local images = {}
local from = 0
local to = 0
local group = 1
local totalGroup = 1
local wall = nil
local initialized = false
local full = false
local selectedThumb = nil
local linked = nil

local viewport = {
    x = 55,  y = 85,
    w = 530, h = 310,
}

local COLS = 4
local SPACING = 10

-- Thumb class for holding thumbnail.
local Thumb = {
    w = 120,
    h = 90,
}
Thumb.__index = Thumb

function Thumb.new(x, y, img)
    local t = setmetatable({
        x = x, y = y, img = img,
        hovered = false,
        selected = false,
    }, Thumb)

    t.imgW, t.imgH = img:getDimensions()
    t.scale = math.min(Thumb.w / t.imgW, Thumb.h / t.imgH)
    local drawW = t.imgW * t.scale
    local drawH = t.imgH * t.scale
    t.centerX = x + (Thumb.w - drawW) / 2
    t.centerY = y + (Thumb.h - drawH) / 2

    return t
end

function Thumb:contains(mx, my)
    return mx >= self.x and
           mx <= self.x + self.w and
           my >= self.y and
           my <= self.y + self.h
end

function Thumb:update(dt)
    local mx, my = love.mouse.getPosition()
    self.hovered = self:contains(mx, my)
end

function Thumb:draw()
    -- Fit image into thumbnail (centered).
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.img, self.centerX, self.centerY, 0, self.scale, self.scale)

    -- Draw thumbnail frame.
    local bg = {0, 0, 0}
    if self.selected then
        bg = {0, 0, 0.9}
    elseif self.hovered then
        bg = {0.1, 0.1, 0.9}
    end
    love.graphics.setColor(bg)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
end

function Thumb:mousepressed(mx, my, button)
    if button == 1 and self:contains(mx, my) then
        wall = self.img
        selectedThumb.selected = false
        self.selected = true
        selectedThumb = self
    end
end


local buttons = {}  -- For prev and next buttons.
local apply = nil

function pattern.enter()
    print("[Pattern] enter")

    if not initialized then
        initialized = true
        local files = util.getFileNames("patterns/free", true)
        -- for i, f in ipairs(files) do
            -- print(i, f)
        -- end

        for i, file in ipairs(files) do
            if love.filesystem.getInfo(file) then
                local img = love.graphics.newImage(file)
                local thumb = Thumb.new(viewport.x + SPACING + ((i-1) % COLS) * (Thumb.w + SPACING),
                                        viewport.y + SPACING + (math.floor((i-1) / COLS) % 3) * (Thumb.h + SPACING),
                                        img)
                table.insert(images, thumb)
            end
        end
        if #images > 0 then
            from = 1
            to = math.min(12, #images)
            images[1].selected = true
            selectedThumb = images[1]
            wall = images[1].img
        end

        local totalGroup = math.ceil(#images / 12)

        table.insert(buttons, ui.Button.new(55, 400, "prev", function()
            if group > 1 then
                group = group - 1
                from = from - 12
                to = from + 11
                buttons[2].enabled = true
                if group == 1 then
                    buttons[1].enabled = false
                end
            end
        end))
        table.insert(buttons, ui.Button.new(120, 400, "next", function()
            if group < totalGroup then
                group = group + 1
                from = from + 12
                to = math.min(to + 12, #images)
                buttons[1].enabled = true
                if group == totalGroup then
                    buttons[2].enabled = false
                end
            end
        end))

        -- Disable prev button initally.
        buttons[1].enabled = false

        apply = ui.Button.new(185, 400, "apply", function()
            linked.image = wall
            linked.w, linked.h = wall:getDimensions()
            fsm.pop()
        end)
    end
end

-- TODO: button[2] is not always enabled (in case #images <= 12)
function pattern.exit()
    group = 1
    from = 1
    to = math.min(12, #images)
    images[1].selected = true
    selectedThumb = images[1]
    wall = images[1].img
    full = false
    buttons[1].enabled = false
    buttons[2].enabled = true
    linked = nil
    print("[Pattern] exit")
end

function pattern.update(dt)
    if not full then
        for i = from, to do
            images[i]:update(dt)
        end
        for _, btn in ipairs(buttons) do
            btn:update(dt)
        end
        if linked then
            apply:update(dt)
        end
    end
end

function pattern.draw()
    love.graphics.setColor(1, 1, 1)
    local w, h = love.graphics.getDimensions()
    local iw, ih = wall:getDimensions()
    for y = 0, h, ih do
        for x = 0, w, iw do
            love.graphics.draw(wall, x, y)
        end
    end

    if not full then
        -- Viewport background: checkerboard
        for i = 0, 9 do
            for j = 0, 9 do
                local isDark = (i + j) % 2 == 0
                if isDark then
                    love.graphics.setColor(0.7, 0.7, 0.7)
                else
                    love.graphics.setColor(0.9, 0.9, 0.9)
                end
                love.graphics.rectangle("fill", viewport.x + j * 53, viewport.y + i * 31, 53, 31)
            end
        end

        for i = from, to do
            images[i]:draw()
        end

        for _, btn in ipairs(buttons) do
            btn:draw()
        end
        if linked then
            apply:draw()
        end
    end
end

function pattern.link(wall)
    linked = wall
end

function pattern.mousepressed(x, y, button)
    if not full then
        for i = from, to do
            images[i]:mousepressed(x, y, button)
        end
        for _, btn in ipairs(buttons) do
            btn:mousepressed(x, y, button)
        end
        if linked then
            apply:mousepressed(x, y, button)
        end
    end
end

function pattern.mousereleased(x, y, button)
    if not full then
        for _, btn in ipairs(buttons) do
            btn:mousereleased(x, y, button)
        end
        if linked then
            apply:mousereleased(x, y, button)
        end
    end
end

function pattern.keypressed(key, scancode, isrepeat)
    if key == "f" then
        full = not full
    end
    if key == "q" then
        fsm.pop()
    end
end

return pattern
