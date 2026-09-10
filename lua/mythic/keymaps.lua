-- Default keymaps, all under <leader>m.
--
-- Set `vim.g.mythic_no_default_keymaps = true` to skip them entirely. An
-- existing mapping is never overwritten, so your own <leader>m... mappings win
-- whichever order they load in.
--
-- Note that <leader> is resolved when the mapping is created, so `mapleader`
-- must be set before the plugin loads -- which is the usual arrangement.
local M = {}

local MAPS = {
    { "mf", function() require("mythic.pick").odds() end, "Mythic: fate chart (pick odds)" },
    { "ms", "<cmd>MythicSceneTest<CR>", "Mythic: scene test" },
    { "me", "<cmd>MythicEventFocus<CR>", "Mythic: random event focus" },
    { "mc", "<cmd>MythicCharacterList<CR>", "Mythic: open Characters list" },
    { "mt", "<cmd>MythicThreadList<CR>", "Mythic: open Threads list" },
    { "mT", function() require("mythic.pick").builtin_table() end, "Mythic: pick a built-in table" },
    { "mr", "<cmd>MythicCustomTable<CR>", "Mythic: roll on a campaign table" },
}

function M.setup()
    if vim.g.mythic_no_default_keymaps then return end

    local leader = vim.g.mapleader or "\\"
    for _, map in ipairs(MAPS) do
        local suffix, rhs, desc = map[1], map[2], map[3]
        -- maparg does not expand <leader>, so probe the resolved form
        if vim.fn.maparg(leader .. suffix, "n") == "" then
            vim.keymap.set("n", "<leader>" .. suffix, rhs, { desc = desc })
        end
    end
end

return M
