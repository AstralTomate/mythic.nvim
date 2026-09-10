-- Resolving the campaign folder.
--
-- A campaign is simply the folder holding its journal, so the campaign is the
-- folder of the file you are editing. If that folder or one above it already has
-- a lists document, that one wins, so notes in subfolders share their campaign's
-- lists and tables.
local M = {}

-- Remembered so that floating scratch buffers -- the list window, the result
-- window, some vim.ui.select implementations -- keep the campaign they were
-- opened from, since they have no path of their own to resolve from.
local last_dir = nil

-- The lists document doubles as the marker for an existing campaign folder.
-- Override the name with `vim.g.mythic_lists_file`.
function M.lists_filename()
    return vim.g.mythic_lists_file or "Mythic Lists.md"
end

local function buffer_dir()
    if vim.bo.buftype ~= "" then return nil end
    local name = vim.api.nvim_buf_get_name(0)
    if name == "" then return nil end
    return vim.fn.fnamemodify(name, ":p:h")
end

function M.dir()
    local start = buffer_dir()
    if not start then return last_dir or vim.fn.getcwd() end

    local home = vim.fn.expand("~")
    local dir = start
    while true do
        if vim.fn.filereadable(dir .. "/" .. M.lists_filename()) == 1 then
            last_dir = dir
            return dir
        end
        if dir == home then break end
        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then break end
        dir = parent
    end

    last_dir = start
    return start
end

-- Point at a campaign explicitly, for commands that take a directory argument.
function M.set_dir(dir)
    last_dir = vim.fn.fnamemodify(vim.fn.expand(dir), ":p"):gsub("[/\\]$", "")
    return last_dir
end

return M
