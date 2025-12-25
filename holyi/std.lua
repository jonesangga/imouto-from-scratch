local types = require("types")

local primitives, FnType = types.primitives, types.FnType
local Int, Bool, String, Null, Unit = types.Int, types.Bool, types.String, types.Null, types.Unit

local procedures = {}

procedures["println"] = {
    type  = FnType({primitives.Any}, primitives.Unit),
    data = {
        arity = 1,
        impl  = function(args, env)
            print(args[1].val)
            return Unit()
        end,
    }
}

procedures["itos"] = {
    type  = FnType({primitives.Int}, primitives.String),
    data = {
        arity = 1,
        impl  = function(args, env)
            return String(tostring(args[1].val))
        end,
    }
}

return {
    procedures = procedures,
}
