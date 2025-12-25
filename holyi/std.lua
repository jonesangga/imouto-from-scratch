local types = require("types")

local IT, FnType = types.IT, types.FnType
local Int, Bool, String, Null = types.Int, types.Bool, types.String, types.Null

local procedures = {}

procedures["println"] = {
    type  = FnType({IT.Any}, IT.Void),
    data = {
        arity = 1,
        impl  = function(args, env)
            print(args[1].val)
            return nil
        end,
    }
}

procedures["itos"] = {
    type  = FnType({IT.Int}, IT.String),
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
