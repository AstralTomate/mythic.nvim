-- Adventure Journal: Characters and Threads with per-project JSON persistence
local M = {}

local characters = {}
local threads = {}
local current_root = nil  -- resolved campaign root directory

-- Walk up from cwd to find the campaign root.
-- Stops at the first directory that has .mythic/ (explicit init) or .git/ (vcs root).
-- Falls back to cwd if neither is found.
local function find_project_root()
    local cwd = vim.fn.getcwd()
    local dir = cwd
    while true do
        if vim.fn.isdirectory(dir .. "/.mythic") == 1 then return dir end
        if vim.fn.isdirectory(dir .. "/.git") == 1 then return dir end
        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then return cwd end  -- reached fs root
        dir = parent
    end
end

local function journal_path()
    return current_root .. "/.mythic/journal.json"
end

local function save()
    if not current_root then return end
    vim.fn.mkdir(current_root .. "/.mythic", "p")
    local ok, json = pcall(vim.fn.json_encode, { characters = characters, threads = threads })
    if not ok then return end
    local f = io.open(journal_path(), "w")
    if f then
        f:write(json)
        f:close()
    end
end

-- Reload when the resolved project root changes (cwd moved to a different campaign).
local function ensure_loaded()
    local root = find_project_root()
    if root == current_root then return end
    current_root = root
    characters = {}
    threads = {}
    local f = io.open(journal_path(), "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
    local ok, data = pcall(vim.fn.json_decode, content)
    if ok and type(data) == "table" then
        characters = data.characters or {}
        threads = data.threads or {}
    end
end

-- Force a root re-detection on the next access (used after :MythicInit).
function M.reset()
    current_root = nil
end

local function find_by_field(list, field, value)
    for i, entry in ipairs(list) do
        if entry[field] == value then return i end
    end
    return nil
end

local function weighted_pick(list)
    if #list == 0 then return nil end
    local pool = {}
    for i, entry in ipairs(list) do
        for _ = 1, entry.count do table.insert(pool, i) end
    end
    return list[pool[math.random(1, #pool)]]
end

-- Characters

function M.add_character(name)
    ensure_loaded()
    local idx = find_by_field(characters, "name", name)
    if idx then
        if characters[idx].count >= 3 then
            return false, name .. " is already at max (x3)"
        end
        characters[idx].count = characters[idx].count + 1
        save()
        return true, name .. " now at x" .. characters[idx].count
    end
    table.insert(characters, { name = name, count = 1 })
    save()
    return true, "Added " .. name
end

function M.remove_character(idx)
    ensure_loaded()
    if not characters[idx] then return false end
    if characters[idx].count > 1 then
        characters[idx].count = characters[idx].count - 1
    else
        table.remove(characters, idx)
    end
    save()
    return true
end

function M.duplicate_character(idx)
    ensure_loaded()
    if not characters[idx] then return false end
    if characters[idx].count >= 3 then return false end
    characters[idx].count = characters[idx].count + 1
    save()
    return true
end

function M.get_characters()
    ensure_loaded()
    return characters
end

function M.roll_character()
    ensure_loaded()
    return weighted_pick(characters)
end

-- Threads

function M.add_thread(text)
    ensure_loaded()
    local idx = find_by_field(threads, "text", text)
    if idx then
        if threads[idx].count >= 3 then
            return false, "Thread already at max (x3)"
        end
        threads[idx].count = threads[idx].count + 1
        save()
        return true, "Thread weight increased to x" .. threads[idx].count
    end
    table.insert(threads, { text = text, count = 1 })
    save()
    return true, "Thread added: " .. text
end

function M.remove_thread(idx)
    ensure_loaded()
    if not threads[idx] then return false end
    if threads[idx].count > 1 then
        threads[idx].count = threads[idx].count - 1
    else
        table.remove(threads, idx)
    end
    save()
    return true
end

function M.duplicate_thread(idx)
    ensure_loaded()
    if not threads[idx] then return false end
    if threads[idx].count >= 3 then return false end
    threads[idx].count = threads[idx].count + 1
    save()
    return true
end

function M.get_threads()
    ensure_loaded()
    return threads
end

function M.roll_thread()
    ensure_loaded()
    return weighted_pick(threads)
end

return M
