-- Adventure Journal: Characters and Threads list state
local M = {}

-- {name: string, count: 1-3}
local characters = {}
-- {text: string, count: 1-3}
local threads = {}

local function find_by_field(list, field, value)
    for i, entry in ipairs(list) do
        if entry[field] == value then return i end
    end
    return nil
end

-- Characters

function M.add_character(name)
    local idx = find_by_field(characters, "name", name)
    if idx then
        if characters[idx].count >= 3 then
            return false, name .. " is already at max (×3)"
        end
        characters[idx].count = characters[idx].count + 1
        return true, name .. " now at ×" .. characters[idx].count
    end
    table.insert(characters, { name = name, count = 1 })
    return true, "Added " .. name
end

function M.remove_character(idx)
    if not characters[idx] then return false end
    if characters[idx].count > 1 then
        characters[idx].count = characters[idx].count - 1
    else
        table.remove(characters, idx)
    end
    return true
end

function M.duplicate_character(idx)
    if not characters[idx] then return false end
    if characters[idx].count >= 3 then return false end
    characters[idx].count = characters[idx].count + 1
    return true
end

function M.get_characters()
    return characters
end

-- Threads

function M.add_thread(text)
    local idx = find_by_field(threads, "text", text)
    if idx then
        if threads[idx].count >= 3 then
            return false, "Thread already at max (×3)"
        end
        threads[idx].count = threads[idx].count + 1
        return true, "Thread weight increased to ×" .. threads[idx].count
    end
    table.insert(threads, { text = text, count = 1 })
    return true, "Thread added: " .. text
end

function M.remove_thread(idx)
    if not threads[idx] then return false end
    if threads[idx].count > 1 then
        threads[idx].count = threads[idx].count - 1
    else
        table.remove(threads, idx)
    end
    return true
end

function M.duplicate_thread(idx)
    if not threads[idx] then return false end
    if threads[idx].count >= 3 then return false end
    threads[idx].count = threads[idx].count + 1
    return true
end

function M.get_threads()
    return threads
end

return M
