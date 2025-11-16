local Character = {}
Character.__index = Character

-- TODO: Cache the characters.
function Character.new(path)
    local c = setmetatable({}, Character)
    c.image = love.graphics.newImage(path)
    c.w     = c.image:getWidth()
    c.h     = c.image:getHeight()
    c.x     = (love.graphics.getWidth() - c.w) / 2
    c.y     = (love.graphics.getHeight() - c.h) / 2
    c.mode  = 1  -- 1 normal, 2 turnleft, 3 turnright, 4 flip.
    return c
end

function Character:draw()
    local cx = love.graphics.getWidth() / 2
    local cy = love.graphics.getHeight() / 2
    local mode = self.mode
    if mode == 1 then
        love.graphics.draw(self.image, self.x, self.y)
    elseif mode == 2 then
        love.graphics.draw(self.image, cx, cy, 0.1, 1, 1, self.w/2, self.h/2)
    elseif mode == 3 then
        love.graphics.draw(self.image, cx, cy, -0.1, 1, 1, self.w/2, self.h/2)
    else
        love.graphics.draw(self.image, self.x + self.w, self.y, 0, -1, 1)
    end
end

return Character
