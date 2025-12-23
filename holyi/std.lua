local types = require("types")

local IT, FnType = types.IT, types.FnType

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

return {
    procedures = procedures,
}
