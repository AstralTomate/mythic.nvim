-- Interactive floating list window for Characters / Threads
local M = {}

local ns = vim.api.nvim_create_namespace("mythic_list")
local WIDTH = 60
local VISIBLE = 10
local HEIGHT = VISIBLE + 2  -- items + empty separator + help line

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
    local animating = false
    local win  -- assigned after open_win

    -- render(anim): draw the window contents.
    -- anim = {line = item_idx, hl = "group"} overrides selection during animation.
    local function render(anim)
        if not (win and vim.api.nvim_win_is_valid(win)) then return end

        local items = opts.get_items()
        local n = #items

        local active_idx, hl_group
        if anim then
            active_idx = anim.line
            hl_group = anim.hl
            -- Keep animated line in view
            if active_idx <= offset then offset = active_idx - 1 end
            if active_idx > offset + VISIBLE then offset = active_idx - VISIBLE end
        else
            selected = n == 0 and 1 or math.max(1, math.min(selected, n))
            active_idx = selected
            hl_group = "CursorLine"
            if selected <= offset then offset = selected - 1 end
            if selected > offset + VISIBLE then offset = selected - VISIBLE end
        end
        offset = math.max(0, offset)

        local lines = {}
        if n == 0 then
            for _ = 1, VISIBLE do table.insert(lines, "") end
            lines[math.floor(VISIBLE / 2)] = "  (empty)"
        else
            for i = offset + 1, math.min(offset + VISIBLE, n) do
                local item = items[i]
                local prefix = (not anim and i == selected) and "> " or "  "
                local count_str = item.count > 1 and (" [x" .. item.count .. "]") or ""
                local max_label = WIDTH - #prefix - #count_str - 2
                local label = #item.label > max_label
                    and (item.label:sub(1, max_label - 1) .. "…")
                    or item.label
                table.insert(lines, prefix .. label .. count_str)
            end
            while #lines < VISIBLE do table.insert(lines, "") end
        end

        local help = "  [a] Add  [d] Dup  [r] Roll  [x] Remove  [q] Close"
        if n > VISIBLE then
            help = help .. "  (" .. active_idx .. "/" .. n .. ")"
        end
        table.insert(lines, "")
        table.insert(lines, help)

        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].modifiable = false

        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        if n > 0 then
            local vis_line = active_idx - offset - 1
            if vis_line >= 0 and vis_line < VISIBLE then
                vim.api.nvim_buf_add_highlight(buf, ns, hl_group, vis_line, 0, -1)
            end
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
        if animating then return end
        local n = #opts.get_items()
        if n > 0 and selected < n then
            selected = selected + 1
            render()
        end
    end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "k", function()
        if animating then return end
        if selected > 1 then
            selected = selected - 1
            render()
        end
    end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "a", function()
        if animating then return end
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
        if animating then return end
        if #opts.get_items() > 0 then
            local ok = opts.on_duplicate(selected)
            if not ok then vim.notify("Already at max (x3)", vim.log.levels.WARN) end
            render()
        end
    end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "x", function()
        if animating then return end
        local n = #opts.get_items()
        if n > 0 then
            opts.on_remove(selected)
            local new_n = #opts.get_items()
            selected = new_n == 0 and 1 or math.min(selected, new_n)
            render()
        end
    end, { buffer = buf, nowait = true })

    -- [r] Roulette roll: weighted random pick with spinning animation
    vim.keymap.set("n", "r", function()
        if animating then return end
        local items = opts.get_items()
        local n = #items
        if n == 0 then
            vim.notify("List is empty", vim.log.levels.WARN)
            return
        end

        animating = true

        -- Build weighted pool and pick winner
        local pool = {}
        for i, item in ipairs(items) do
            for _ = 1, item.count do table.insert(pool, i) end
        end
        local winner_idx = pool[math.random(1, #pool)]

        -- Animation sequence: {item_index, delay_ms}
        local seq = {}

        -- Fast phase: 12 steps cycling forward at 60ms
        local pos = math.random(1, n)
        for _ = 1, 12 do
            pos = (pos % n) + 1
            table.insert(seq, { pos, 60 })
        end

        -- Slow approach: 8 sequential steps ending on winner, with increasing delays
        for i = 1, 8 do
            local back = 8 - i
            local idx = ((winner_idx - 1 - back) % n + n) % n + 1
            table.insert(seq, { idx, 80 + i * 30 })  -- 110, 140, ..., 320ms
        end

        local function step(i)
            if not (win and vim.api.nvim_win_is_valid(win)) then
                animating = false
                return
            end
            if i > #seq then
                animating = false
                local label = items[winner_idx].label
                -- Strip trailing 's' from title to get singular ("Characters" → "Character")
                local singular = opts.title:sub(1, -2)
                local result = singular .. ": " .. label
                close()
                require("mythic.buffer").show(result)
                return
            end
            render({ line = seq[i][1], hl = "IncSearch" })
            vim.defer_fn(function() step(i + 1) end, seq[i][2])
        end

        step(1)
    end, { buffer = buf, nowait = true })
end

return M
