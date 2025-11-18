local Wallpaper = {}
Wallpaper.__index = Wallpaper

function Wallpaper.new(path)
    local wall = setmetatable({}, Wallpaper)
    wall.image = love.graphics.newImage(path)
    wall.w     = wall.image:getWidth()
    wall.h     = wall.image:getHeight()
    return wall
end

function Wallpaper:draw()
    local w, h = love.graphics.getDimensions()
    for y = 0, h, self.h do
        for x = 0, w, self.w do
            love.graphics.draw(self.image, x, y)
        end
    end
end

return Wallpaper
