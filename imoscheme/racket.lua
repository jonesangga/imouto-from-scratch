local eval  = require("eval")

local procedures = {}

procedures["add1"] = function(args, env)
    local num = eval(args.car, env)
    if type(num) ~= "number" then
        error("<add1> arg must be number")
    end
    return num + 1
end

procedures["sub1"] = function(args, env)
    local num = eval(args.car, env)
    if type(num) ~= "number" then
        error("<sub1> arg must be number")
    end
    return num - 1
end

return procedures
