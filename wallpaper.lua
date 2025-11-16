local Wallpaper = {}
Wallpaper.__index = Wallpaper

function Wallpaper.new(path)
    return setmetatable({
        image = love.graphics.newImage(path)
    }, Wallpaper)
end

function Wallpaper:draw()
    local ww = 64
    local w, h = love.graphics.getDimensions()
    for y = 0, h, ww do
        for x = 0, w, ww do
            love.graphics.draw(self.image, x, y)
        end
    end
end

return Wallpaper
