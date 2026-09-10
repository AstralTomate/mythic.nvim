-- Selection wrappers, so keymaps do not have to build UI of their own. These
-- use vim.ui.select, which picks up whatever selector is installed (snacks,
-- telescope, fzf-lua, dressing) and falls back to the built-in prompt.
local M = {}

-- 50/50 first: it is by far the most common call, and the rest read outwards
-- from there rather than alphabetically or by probability.
local ODDS = {
    "50/50",
    "Certain",
    "Nearly Certain",
    "Very Likely",
    "Likely",
    "Unlikely",
    "Very Unlikely",
    "Nearly Impossible",
    "Impossible",
}

function M.odds()
    vim.ui.select(ODDS, { prompt = "Fate Chart odds:" }, function(choice)
        if choice then vim.cmd("MythicFateChart " .. choice) end
    end)
end

function M.builtin_table()
    local names = require("mythic.tables.registry")
    vim.ui.select(names, { prompt = "Mythic table:" }, function(choice)
        if choice then vim.cmd("MythicTables " .. choice) end
    end)
end

return M
