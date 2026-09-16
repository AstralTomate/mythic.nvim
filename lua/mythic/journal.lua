-- Adventure lists: Characters and Threads stored in a hand-editable markdown
-- document that sits next to the campaign's journal.
--
-- The document is the single source of truth. It looks like this:
--
--     ## Threads
--
--     - Find out who poisoned the well (x2)
--     - Escape the sunken city
--
--     ## Characters
--
--     - Sister Vell (x3)
--     - The Tinker
--
-- Anything outside those two sections is preserved on write, so the file can
-- hold ordinary notes as well.
local M = {}

local campaign = require("mythic.campaign")
local weight = require("mythic.weight")

local characters = {}
local threads = {}
local doc_lines = {}      -- the file as last read, used to preserve unmanaged content
local current_dir = nil   -- resolved campaign folder
local current_path = nil  -- resolved markdown document


-- Section headings, matched case-insensitively.
local SECTIONS = {
    { name = "threads", heading = "## Threads" },
    { name = "characters", heading = "## Characters" },
}

local BULLET = "^%s*[%-%*%+]%s+"

-- A heading that ends a `##` section (level 1 or 2; `###` stays inside).
local function is_section_break(line)
    return line:match("^#%s") ~= nil or line:match("^##%s") ~= nil
end

local function section_of(line)
    local text = line:match("^##%s+(.-)%s*$")
    if not text then return nil end
    text = text:lower()
    for _, s in ipairs(SECTIONS) do
        if text == s.name then return s.name end
    end
    return nil
end

-- Parse one bullet into text and weight. An optional task checkbox is stripped.
-- Weight is clamped to Mythic's 1-3; a bullet with no weight is x1.
local function parse_entry(line)
    local body = line:gsub(BULLET, "", 1)
    body = body:gsub("^%[[ xX]%]%s*", "")
    body = body:gsub("%s+$", "")
    if body == "" then return nil end

    local text, count = weight.split(body)
    return text, math.min(3, count)
end

local function render_entry(text, count)
    return "- " .. weight.join(text, count)
end

local function parse_document(lines)
    local parsed = { threads = {}, characters = {} }
    local notes = { threads = {}, characters = {} }
    local active = nil

    for _, line in ipairs(lines) do
        local section = section_of(line)
        if section then
            active = section
        elseif active and is_section_break(line) then
            active = nil
        elseif active then
            if line:match(BULLET) then
                local text, count = parse_entry(line)
                if text then weight.accumulate(parsed[active], text, count, 3) end
            elseif line:match("%S") then
                table.insert(notes[active], line)
            end
        end
    end

    return parsed, notes
end

-- Rebuild the file, replacing the managed sections in place and appending any
-- that are missing. Non-bullet prose inside a section is kept above the list.
local function render_document(lines, notes)
    local out = {}
    local seen = {}
    local i = 1

    local function emit_section(name)
        local list = (name == "threads") and threads or characters
        table.insert(out, "")
        for _, note in ipairs(notes[name] or {}) do
            table.insert(out, note)
        end
        if #(notes[name] or {}) > 0 then table.insert(out, "") end
        for _, entry in ipairs(list) do
            table.insert(out, render_entry(entry.text, entry.count))
        end
        table.insert(out, "")
    end

    while i <= #lines do
        local line = lines[i]
        local section = section_of(line)
        if section then
            -- A repeated heading is dropped: parsing already merged its entries
            -- into the first occurrence, so keeping it would double them.
            if not seen[section] then
                seen[section] = true
                table.insert(out, line)
                emit_section(section)
            end
            -- skip the old body
            i = i + 1
            while i <= #lines and not (section_of(lines[i]) or is_section_break(lines[i])) do
                i = i + 1
            end
        else
            table.insert(out, line)
            i = i + 1
        end
    end

    for _, s in ipairs(SECTIONS) do
        if not seen[s.name] then
            if #out > 0 and out[#out]:match("%S") then table.insert(out, "") end
            table.insert(out, s.heading)
            emit_section(s.name)
        end
    end

    -- collapse runs of blank lines and trim trailing ones
    local tidy = {}
    for _, line in ipairs(out) do
        if line:match("%S") or (#tidy > 0 and tidy[#tidy]:match("%S")) then
            table.insert(tidy, line)
        end
    end
    while #tidy > 0 and not tidy[#tidy]:match("%S") do table.remove(tidy) end

    return tidy
end

local function read_lines(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local lines = {}
    for line in f:lines() do table.insert(lines, (line:gsub("\r$", ""))) end
    f:close()
    return lines
end

local function save()
    if not current_path then return end
    local base = doc_lines
    local _, notes = parse_document(base)
    local lines = render_document(base, notes)

    local f = io.open(current_path, "w")
    if not f then
        vim.notify("Mythic: cannot write " .. current_path, vim.log.levels.ERROR)
        return
    end
    f:write(table.concat(lines, "\n"), "\n")
    f:close()

    doc_lines = lines

    -- keep an open buffer for the document in sync
    local bufnr = vim.fn.bufnr(current_path)
    if bufnr > 0 and vim.api.nvim_buf_is_loaded(bufnr) then
        vim.cmd("silent! checktime " .. bufnr)
    end
end

local function load_document()
    characters = {}
    threads = {}
    doc_lines = read_lines(current_path) or {}
    local parsed = parse_document(doc_lines)
    threads = parsed.threads
    characters = parsed.characters
end

-- Re-resolve the campaign folder and re-read the document. The file is small
-- and every entry point is user-driven, so reading it each time is cheaper than
-- getting cache invalidation wrong -- mtime has one-second granularity and would
-- silently miss a hand-edit made in the same second as one of our own writes.
local function ensure_loaded()
    local dir = campaign.dir()
    current_dir = dir
    current_path = dir .. "/" .. campaign.lists_filename()
    load_document()
end

-- Resolve the campaign folder now, while a real file buffer is still current.
-- Commands call this before opening a floating window, since the float itself
-- is a scratch buffer with no path of its own.
function M.sync()
    ensure_loaded()
end

function M.path()
    ensure_loaded()
    return current_path
end

-- Create the document with empty sections if it does not exist yet.
function M.ensure_document(dir)
    if dir then
        current_dir = campaign.set_dir(dir)
        current_path = current_dir .. "/" .. campaign.lists_filename()
        load_document()
    else
        ensure_loaded()
    end
    if vim.fn.filereadable(current_path) == 0 then save() end
    return current_path
end

local function find_by_text(list, text)
    for i, entry in ipairs(list) do
        if entry.text == text then return i end
    end
    return nil
end

local function add_entry(list, text, label)
    local idx = find_by_text(list, text)
    if idx then
        if list[idx].count >= 3 then
            return false, label .. " already at max (x3)"
        end
        list[idx].count = list[idx].count + 1
        save()
        return true, text .. " now at x" .. list[idx].count
    end
    table.insert(list, { text = text, count = 1 })
    save()
    return true, "Added " .. text
end

local function remove_entry(list, idx)
    if not list[idx] then return false end
    if list[idx].count > 1 then
        list[idx].count = list[idx].count - 1
    else
        table.remove(list, idx)
    end
    save()
    return true
end

local function duplicate_entry(list, idx)
    if not list[idx] then return false end
    if list[idx].count >= 3 then return false end
    list[idx].count = list[idx].count + 1
    save()
    return true
end

-- Rename the entry at `idx`, keeping its weight. A (x2) typed onto the new name
-- sets the weight instead. Renaming onto an existing entry merges the two, as if
-- the name had been added again, up to x3. Returns ok, message, and the entry's
-- index afterwards so the list window can keep it selected.
local function rename_entry(list, idx, new_text)
    local entry = list[idx]
    if not entry then return false, "Nothing to rename", idx end

    local input = vim.trim(new_text or "")
    local text, typed = weight.split(input)
    text = vim.trim(text)
    if text == "" then return false, "Name cannot be empty", idx end
    -- split hands the input back untouched when there is no weight suffix
    local count = text ~= input and math.min(3, typed) or entry.count

    if text == entry.text and count == entry.count then
        return true, nil, idx
    end

    local other = find_by_text(list, text)
    if other and other ~= idx then
        list[other].count = math.min(3, list[other].count + count)
        table.remove(list, idx)
        if other > idx then other = other - 1 end
        save()
        return true, "Merged into " .. text .. " (x" .. list[other].count .. ")", other
    end

    local old_text = entry.text
    entry.text = text
    entry.count = count
    save()
    if old_text == text then
        return true, text .. " now at x" .. count, idx
    end
    return true, "Renamed " .. old_text .. " to " .. text, idx
end

-- Characters

function M.add_character(name)
    ensure_loaded()
    return add_entry(characters, name, "Character")
end

function M.remove_character(idx)
    ensure_loaded()
    return remove_entry(characters, idx)
end

function M.duplicate_character(idx)
    ensure_loaded()
    return duplicate_entry(characters, idx)
end

function M.rename_character(idx, text)
    ensure_loaded()
    return rename_entry(characters, idx, text)
end

function M.get_characters()
    ensure_loaded()
    return characters
end

function M.roll_character()
    ensure_loaded()
    return weight.pick(characters)
end

-- Threads

function M.add_thread(text)
    ensure_loaded()
    return add_entry(threads, text, "Thread")
end

function M.remove_thread(idx)
    ensure_loaded()
    return remove_entry(threads, idx)
end

function M.duplicate_thread(idx)
    ensure_loaded()
    return duplicate_entry(threads, idx)
end

function M.rename_thread(idx, text)
    ensure_loaded()
    return rename_entry(threads, idx, text)
end

function M.get_threads()
    ensure_loaded()
    return threads
end

function M.roll_thread()
    ensure_loaded()
    return weight.pick(threads)
end

return M
