-- Audio class. A simple wrapper for love.audio with the same API names for handling missing audio.

local Audio = {}
Audio.__index = Audio

function Audio.new(path, type)
    local audio = nil
    if love.filesystem.getInfo(path) then
        audio = love.audio.newSource(path, type)
        audio:setLooping(true)
        audio:setVolume(0.8)
    else
        print("[Warning] " .. path .. " doesn't exits")
    end
    return setmetatable({
        audio = audio,
    }, Audio)
end

function Audio:play()
    if self.audio then
        self.audio:play()
    end
end

function Audio:pause()
    if self.audio then
        self.audio:pause()
    end
end

function Audio:stop()
    if self.audio then
        self.audio:stop()
    end
end

-- Use later.
-- function Audio:keypressed(key, scancode, isrepeat)
    -- if key == "space" then
        -- if music:isPlaying() then
            -- music:pause()
        -- else
            -- music:play()
        -- end
    -- elseif key == "s" then
        -- music:stop()
    -- elseif key == "up" then
        -- local v = math.min(1, music:getVolume() + 0.1)
        -- music:setVolume(v)
    -- elseif key == "down" then
        -- local v = math.max(0, music:getVolume() - 0.1)
        -- music:setVolume(v)
    -- elseif key == "right" then
        -- -- seek forward 5 seconds
        -- local pos = music:tell()
        -- music:seek(pos + 5)
    -- elseif key == "left" then
        -- -- seek backward 5 seconds
        -- local pos = music:tell()
        -- music:seek(math.max(0, pos - 5))
    -- end
-- end

-- function love.draw()
    -- love.graphics.printf(("Playing: %s\nLooping: %s\nVolume: %.2f\nPosition: %.2f s"):format(
        -- tostring(music:isPlaying()),
        -- tostring(music:isLooping()),
        -- music:getVolume(),
        -- music:tell()
    -- ), 10, 60, love.graphics.getWidth())
-- end

return Audio
