-- A stack-based Finite State Machine implemented as a singleton.
-- There is exactly one state at any time.
-- Hence pop-ups, settings, and pause screen must use whole screen.

local fsm = {}
local states = {}
local top = 0
local current = nil

function fsm.push(state)
    if current and current.pauseAudio then
        current.pauseAudio()
    end
    top = top + 1
    states[top] = state
    current = state
    current.enter()
end

function fsm.pop()
    assert(top > 0, "no state to pop")
    current.exit()
    top = top - 1
    current = states[top]
    if current.continueAudio then
        current.continueAudio()
    end
end

function fsm.update(dt)
    current.update(dt)
end

function fsm.draw()
    current.draw()
end

function fsm.mousepressed(x, y, button)
    current.mousepressed(x, y, button)
end

function fsm.mousereleased(x, y, button)
    current.mousereleased(x, y, button)
end

function fsm.keypressed(key, scancode, isrepeat)
    current.keypressed(key, scancode, isrepeat)
end

return fsm
