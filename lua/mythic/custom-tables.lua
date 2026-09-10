-- Custom campaign roll tables.
--
-- One markdown file per table in <campaign>/tables/, one result per line:
--
--     tables/Sanctum Rumors.md
--     ├─ A portal flickers in the east wing
--     ├─ The relics have been rearranged overnight
--     └─ Wong is asking about the missing tome
--
-- The table's name is its file name without the extension. Repeating a line
-- makes that result likelier, since every line is one entry in the draw.
local M = {}

local campaign = require("mythic.campaign")

local function subfolder()
    return vim.g.mythic_tables_dir or "tables"
end

function M.dir()
    return campaign.dir() .. "/" .. subfolder()
end

-- Available tables, sorted by name. Paths are resolved here so that callers can
-- hold on to them across an async picker, when the campaign is no longer
-- resolvable from the current buffer.
function M.list()
    local dir = M.dir()
    if vim.fn.isdirectory(dir) == 0 then return {}, dir end

    local found = {}
    for _, entry in ipairs(vim.fn.readdir(dir) or {}) do
        local name = entry:match("^(.+)%.md$")
        if name and vim.fn.filereadable(dir .. "/" .. entry) == 1 then
            table.insert(found, { name = name, path = dir .. "/" .. entry })
        end
    end
    table.sort(found, function(a, b) return a.name:lower() < b.name:lower() end)
    return found, dir
end

-- Every non-blank line is one result. Markdown scaffolding is skipped --
-- frontmatter, headings, horizontal rules -- and a leading list bullet, task
-- checkbox or "1." number is stripped, since results are naturally written as
-- a markdown list.
function M.entries(path)
    local lines = vim.fn.readfile(path)
    if not lines then return {} end

    -- skip frontmatter, but only when it opens on the very first line, so that a
    -- `---` rule further down is treated as a rule
    local first = 1
    if lines[1] and lines[1]:match("^%-%-%-%s*$") then
        for i = 2, #lines do
            if lines[i]:match("^%-%-%-%s*$") then
                first = i + 1
                break
            end
        end
    end

    local entries = {}
    for i = first, #lines do
        local line = lines[i]:gsub("\r$", ""):gsub("^%s+", ""):gsub("%s+$", "")
        local scaffolding = line == ""
            or line:match("^#")          -- heading
            or line:match("^%-%-%-+$")   -- horizontal rule
            or line:match("^%*%*%*+$")
            or line:match("^===+$")
            or line:match("^>")          -- blockquote / callout marker
        if not scaffolding then
            line = line:gsub("^[%-%*%+]%s+", "")
            line = line:gsub("^%d+[%.%)]%s+", "")
            line = line:gsub("^%[[ xX]%]%s*", "")
            if line ~= "" then table.insert(entries, line) end
        end
    end
    return entries
end

function M.roll(path)
    local entries = M.entries(path)
    if #entries == 0 then return nil end
    return entries[math.random(1, #entries)]
end

local function show(name, result)
    local text = name .. ": " .. result
    print(text)
    require("mythic.buffer").show(text)
end

-- Roll on `name` if given, otherwise pick a table first.
function M.prompt(name)
    local found, dir = M.list()

    if #found == 0 then
        vim.notify("No custom tables found. Add markdown files to " .. dir,
            vim.log.levels.WARN)
        return
    end

    if name and name ~= "" then
        local wanted = name:lower():gsub("%.md$", "")
        for _, t in ipairs(found) do
            if t.name:lower() == wanted then
                local result = M.roll(t.path)
                if result then show(t.name, result)
                else vim.notify(t.name .. " has no entries", vim.log.levels.WARN) end
                return
            end
        end
        vim.notify("No custom table named '" .. name .. "' in " .. dir, vim.log.levels.WARN)
        return
    end

    local names = {}
    for _, t in ipairs(found) do table.insert(names, t.name) end

    vim.ui.select(names, { prompt = "Roll on custom table:" }, function(_, idx)
        if not idx then return end
        local t = found[idx]
        local result = M.roll(t.path)
        if result then show(t.name, result)
        else vim.notify(t.name .. " has no entries", vim.log.levels.WARN) end
    end)
end

-- Command-line completion over the campaign's table names.
function M.complete(lead)
    local out = {}
    for _, t in ipairs((M.list())) do
        if t.name:lower():sub(1, #lead) == lead:lower() then table.insert(out, t.name) end
    end
    return out
end

return M
