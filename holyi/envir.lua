local Envir = {}
Envir.__index = Envir

function Envir.new(names, parent)
    return setmetatable({ names = names or {}, parent = parent }, Envir)
end

function Envir:branch(names)
    return Envir.new(names, self)
end

function Envir:add_module(mod)
    for key, val in pairs(mod) do
        self.names[key] = val
    end
end

function Envir:define(key, val)
    self.names[key] = val
end

function Envir:get(key)
    if self.names[key] ~= nil then
        return self.names[key]
    elseif self.parent then
        return self.parent:get(key)
    else
        error("unbound variable " .. key)
    end
end

function Envir:set(key, val)
    if self.names[key] ~= nil then
        self.names[key] = val
    elseif self.parent then
        self.parent:set(key, val)
    else
        error("unbound variable " .. key)
    end
end

return Envir
