-- Imo Scheme state as singleton.

local State = {
    base_stack = {},
}

function State.push_base(path)
    if path == "." then
        table.insert(State.base_stack, ".")
    else
        -- Normalize separators (for windows?).
        path = path:gsub("\\", "/")
        -- Remove trailing slash.
        path = path:gsub("/+$", "")
        -- Extract directory.
        local dir = path:match("^(.*)/[^/]+$") or "."
        table.insert(State.base_stack, dir)
    end
end

function State.current_base()
    return State.base_stack[#State.base_stack]
end

function State.resolve(rel)
    -- if rel:match("^[/\\]") then return rel end -- absolute
    return State.current_base() .. "/" .. rel
end

return State
