local inspect = require("libraries/inspect")

local util = {}

function util.repr(x)
    if x == true then
        print("#t")
    elseif x == false then
        print("#f")
    else
        print(inspect(x))
    end
end

return util
