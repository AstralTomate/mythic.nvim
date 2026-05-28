-- Interactive floating list window for Characters / Threads
local M = {}

local ns = vim.api.nvim_create_namespace("mythic_list")
local WIDTH = 52
local VISIBLE = 10
local HEIGHT = VISIBLE + 2  -- items + empty line + help line

-- opts:
--   title        string
--   get_items    function() -> list of {label: string, count: number}
--   on_add       function(text) -> ok, msg
--   on_remove    function(idx)
--   on_duplicate function(idx) -> bool
function M.show(opts)
    local buf = vim.api.nvim_create_buf(false, true)
    local selected = 1
    local offset = 0
    local win

    local function render()
        if not (win and vim.api.nvim_win_is_valid(win)) then return end

        local items = opts.get_items()
        local n = #items

        -- Clamp selection
        selected = n == 0 and 1 or math.max(1, math.min(selected, n))

        -- Scroll to keep selected in view
        if selected <= offset then offset = selected - 1 end
        if selected > offset + VISIBLE then offset = selected - VISIBLE end
        offset = math.max(0, offset)

        local lines = {}

        if n == 0 then
            for _ = 1, VISIBLE do table.insert(lines, "") end
            lines[math.floor(VISIBLE / 2)] = "  (empty)"
        else
            for i = offset + 1, math.min(offset + VISIBLE, n) do
                local item = items[i]
                local prefix = i == selected and "> " or "  "
                local count_str = item.count > 1 and (" [x" .. item.count .. "]") or ""
                local max_label = WIDTH - #prefix - #count_str - 2
                local label = #item.label > max_label
                    and (item.label:sub(1, max_label - 1) .. "…")
                    or item.label
                table.insert(lines, prefix .. label .. count_str)
            end
            while #lines < VISIBLE do table.insert(lines, "") end
        end

        local help = "  [a] Add  [d] Dup  [x] Remove  [q] Close"
        if n > VISIBLE then
            help = help .. "  (" .. selected .. "/" .. n .. ")"
        end
        table.insert(lines, "")
        table.insert(lines, help)

        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].modifiable = false

        -- Highlight the selected row
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        if n > 0 then
            vim.api.nvim_buf_add_highlight(buf, ns, "CursorLine", selected - offset - 1, 0, -1)
        end
    end

    local screen_lines = vim.opt.lines:get()
    local screen_cols = vim.opt.columns:get()
    local row = math.floor((screen_lines - HEIGHT) / 2) - 1
    local col = math.floor((screen_cols - WIDTH) / 2) - 1

    win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = WIDTH,
        height = HEIGHT,
        row = row,
        col = col,
        border = "rounded",
        title = " Mythic — " .. opts.title .. " ",
        title_pos = "center",
    })

    vim.wo[win].cursorline = false
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false

    render()

    local function close()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end

    vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })

    vim.keymap.set("n", "j", function()
        local n = #opts.get_items()
        if n > 0 and selected < n then
            selected = selected + 1
            render()
        end
    end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "k", function()
        if selected > 1 then
            selected = selected - 1
            render()
        end
    end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "a", function()
        vim.ui.input({ prompt = "Add to " .. opts.title .. ": " }, function(input)
            if input and input ~= "" then
                local ok, msg = opts.on_add(input)
                if msg then vim.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.WARN) end
                selected = #opts.get_items()
                render()
            end
        end)
    end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "d", function()
        local n = #opts.get_items()
        if n > 0 then
            local ok = opts.on_duplicate(selected)
            if not ok then vim.notify("Already at max (×3)", vim.log.levels.WARN) end
            render()
        end
    end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "x", function()
        local n = #opts.get_items()
        if n > 0 then
            opts.on_remove(selected)
            local new_n = #opts.get_items()
            selected = new_n == 0 and 1 or math.min(selected, new_n)
            render()
        end
    end, { buffer = buf, nowait = true })
end

return M
