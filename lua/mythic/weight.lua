-- The trailing weight on a list or table line, written (x2).
--
-- Only the last bracket group is considered, so an entry can carry a
-- parenthesised note of its own: "Doctor Strange (Mentor) (x2)" is
-- "Doctor Strange (Mentor)" at x2. Braces and square brackets are read too, and
-- the × sign needs its own patterns because it is multibyte.
local M = {}

local PATTERNS = {}
for _, pair in ipairs({ { "{", "}" }, { "%(", "%)" }, { "%[", "%]" } }) do
    for _, sign in ipairs({ "[xX]", "×" }) do
        table.insert(PATTERNS,
            "^(.-)%s*" .. pair[1] .. "%s*" .. sign .. "%s*(%d+)%s*" .. pair[2] .. "$")
    end
end

-- Split a line into its text and weight. Returns the line unchanged at x1 when
-- there is no weight suffix. Callers clamp the count if their list has a cap.
function M.split(s)
    for _, pattern in ipairs(PATTERNS) do
        local text, n = s:match(pattern)
        if text and text ~= "" then
            return text, math.max(1, tonumber(n))
        end
    end
    return s, 1
end

-- Write text with its weight, omitting the suffix at x1.
function M.join(text, count)
    if count > 1 then return text .. " (x" .. count .. ")" end
    return text
end

-- Pick one entry from a { {text, count}, ... } list, weighted by count.
function M.pick(list)
    if #list == 0 then return nil end
    local pool = {}
    for i, entry in ipairs(list) do
        for _ = 1, entry.count do table.insert(pool, i) end
    end
    return list[pool[math.random(1, #pool)]]
end

-- Merge into `list`, summing the counts of repeated text. `cap` limits the
-- resulting count when given.
function M.accumulate(list, text, count, cap)
    for _, entry in ipairs(list) do
        if entry.text == text then
            entry.count = entry.count + count
            if cap then entry.count = math.min(cap, entry.count) end
            return entry
        end
    end
    local entry = { text = text, count = cap and math.min(cap, count) or count }
    table.insert(list, entry)
    return entry
end

return M
