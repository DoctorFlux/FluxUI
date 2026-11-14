-- Narrow desktop model of the native macro clauses used by roster drivers.
-- Unit existence and group flags are independent inputs, so tests can reproduce
-- Forever's observed stale group flag instead of assuming the requested result.
return function(context)
    return function(options)
        for clause in options:gmatch("[^;]+") do
            local matched, conditional = false, false
            for block in clause:gmatch("%b[]") do
                conditional = true
                local unit, okay = "target", true
                for term in block:sub(2, -2):gmatch("[^,]+") do
                    if term:sub(1, 1) == "@" then unit = term:sub(2)
                    elseif term == "exists" then okay = okay and not not context.exists(unit)
                    elseif term == "noexists" then okay = okay and not context.exists(unit)
                    elseif term == "petbattle" then okay = okay and not not context.petbattle()
                    elseif term == "group:raid" then okay = okay and context.group() == "raid"
                    elseif term == "group:party" then okay = okay and context.group() == "party"
                    else error("unmodeled roster condition: " .. term) end
                end
                matched = matched or okay
            end
            if matched or not conditional then
                return clause:gsub("%b[]", ""):match("^%s*(.-)%s*$")
            end
        end
    end
end
