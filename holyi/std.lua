local types = require("types")

local IT = types.IT

local procedures = {}

procedures["print"] = {
    arity = 1,
    sig   = types.fntype({IT.Any}, IT.Void),

    impl  = function(args, env)
        print(args[1].val)
        return nil
    end,
}

return {
    procedures = procedures,
}
