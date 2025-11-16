function love.conf(t)
    t.window.title  = "Imouto From Scratch"
    t.window.width  = 640
    t.window.height = 480

    -- Use this later.
    -- t.window.width = 1280  -- 2x
    -- t.window.height = 960  -- 2x

    t.modules.joystick = false
    t.modules.physics  = false
    t.modules.video    = false
end
