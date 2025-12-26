local types = require("types")

local primitives, FnType, GenericFnType = types.primitives, types.FnType, types.GenericFnType
local Int, Bool, String, Null, unit = types.Int, types.Bool, types.String, types.Null, types.unit
local ArrayType = types.ArrayType
local TypeVar = types.TypeVar

local procedures = {}

procedures["println"] = {
    type  = FnType({primitives.Any}, primitives.Unit),
    data = {
        arity = 1,
        impl  = function(args, env)
            print(args[1].val)
            return unit
        end,
    }
}

procedures["itos"] = {
    type  = FnType({primitives.Int}, primitives.String),
    data = {
        arity = 1,
        impl  = function(args, env)
            return String.new(tostring(args[1].val))
        end,
    }
}

procedures["push"] = {
    type  = GenericFnType({"T"}, {ArrayType(TypeVar("T")), TypeVar("T")}, primitives.Unit),
    data = {
        arity = 2,
        impl  = function(args, env)
            table.insert(args[1].val, args[2])
            return unit
        end,
    }
}

procedures["pop"] = {
    type  = GenericFnType({"T"}, {ArrayType(TypeVar("T"))}, TypeVar("T")),
    data = {
        arity = 1,
        impl  = function(args, env)
            local arr = args[1].val
            if #arr == 0 then
                error("cannot pop empty array")
            end
            return table.remove(arr)
        end,
    }
}

return {
    procedures = procedures,
}
