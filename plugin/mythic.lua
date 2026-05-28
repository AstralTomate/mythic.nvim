math.randomseed(os.time() + vim.fn.getpid())

local function get_odds_completion()
	return {
		"Impossible",
		"Nearly Impossible",
		"Very Unlikely",
		"Unlikely",
		"50/50",
		"Likely",
		"Very Likely",
		"Nearly Certain",
		"Certain",
	}
end

local function get_table_keys(_leader, _cmd, _line)
	return require("mythic.tables.registry")
end

vim.api.nvim_create_user_command("MythicTables", function(opts)
	local result = require("mythic").print_table_elements(opts)
	print(result)
	require("mythic.buffer").show(result)
end, {
	nargs = 1,
	complete = get_table_keys,
})

vim.api.nvim_create_user_command("MythicEventFocus", function()
	local result = require("mythic.random-event-focus").get_random_event_focus()

	-- NPC Action/Negative/Positive → roll from Characters list (not "New NPC", that's a fresh character)
	if result:find("NPC Action") or result:find("NPC Negative") or result:find("NPC Positive") then
		local entry = require("mythic.journal").roll_character()
		result = result .. "\n" .. (entry and ("Character: " .. entry.name) or "(No characters in list)")
	-- Any Thread focus → roll from Threads list
	elseif result:find("Thread") then
		local entry = require("mythic.journal").roll_thread()
		result = result .. "\n" .. (entry and ("Thread: " .. entry.text) or "(No threads in list)")
	end

	print(result)
	require("mythic.buffer").show(result)
end, {
	nargs = 0,
})

vim.api.nvim_create_user_command("MythicSceneAdjustment", function()
	local result = require("mythic.scene-adjustment").get_scene_adjustment()
	print(result)
	require("mythic.buffer").show(result)
end, {
	nargs = 0,
})

-- MythicChaos command
vim.api.nvim_create_user_command("MythicChaos", function(opts)
	local state = require("mythic.state")
	local arg = opts.fargs[1]

	if not arg then
		print("Chaos Factor: " .. state.get_chaos_factor())
	elseif arg == "+" then
		state.adjust_chaos_factor(1)
		print("Chaos Factor: " .. state.get_chaos_factor())
	elseif arg == "-" then
		state.adjust_chaos_factor(-1)
		print("Chaos Factor: " .. state.get_chaos_factor())
	else
		local value = tonumber(arg)
		if value then
			state.set_chaos_factor(value)
			print("Chaos Factor: " .. state.get_chaos_factor())
		else
			vim.notify("Invalid argument. Use +, -, or a number.", vim.log.levels.ERROR)
		end
	end
end, { nargs = "?" })

-- MythicFateCheck command
vim.api.nvim_create_user_command("MythicFateCheck", function(opts)
	local fate = require("mythic.fate")
	local odds = opts.fargs[1] or "50/50"

	local result, err = fate.fate_check(odds)
	if not result then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	-- Format output
	local output = result.exceptional and ("Exceptional " .. result.answer) or result.answer
	output = output
		.. string.format(" [%d+%d%+d=%d]", result.roll.die1, result.roll.die2, result.roll.modifier, result.roll.final)

	if result.random_event then
		output = output .. " ⚠ Random Event!"
	end

	print(output)
	require("mythic.buffer").show(output)
end, {
	nargs = "?",
	complete = get_odds_completion,
})

-- MythicFateChart command
vim.api.nvim_create_user_command("MythicFateChart", function(opts)
	local fate = require("mythic.fate")
	local odds = opts.fargs[1] or "50/50"

	local result, err = fate.fate_chart(odds)
	if not result then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	-- Format output
	local output = result.exceptional and ("Exceptional " .. result.answer) or result.answer
	output = output .. string.format(" [d100=%d (%d,%d)]", result.roll.percentile, result.roll.die1, result.roll.die2)

	if result.random_event then
		output = output .. " ⚠ Random Event!"
	end

	print(output)
	require("mythic.buffer").show(output)
end, {
	nargs = "?",
	complete = get_odds_completion,
})

-- MythicSceneTest command
vim.api.nvim_create_user_command("MythicSceneTest", function()
	local scene = require("mythic.scene")
	local result = scene.test_scene()

	local output = string.format("%s [%d vs CF %d]", result.result, result.roll, result.chaos_factor)
	print(output)
	require("mythic.buffer").show(output)
end, { nargs = 0 })

-- MythicInit: mark a directory as campaign root and initialize .mythic/
-- Usage: :MythicInit [path]  (defaults to cwd)
vim.api.nvim_create_user_command("MythicInit", function(opts)
	local arg = opts.fargs[1]
	local dir = arg and vim.fn.fnamemodify(vim.fn.expand(arg), ":p"):gsub("[/\\]$", "")
		or vim.fn.getcwd()
	vim.fn.mkdir(dir .. "/.mythic", "p")
	require("mythic.journal").reset()
	vim.notify("Mythic campaign initialized in " .. dir, vim.log.levels.INFO)
end, { nargs = "?", complete = "dir" })

-- MythicCharacterAdd command
vim.api.nvim_create_user_command("MythicCharacterAdd", function(opts)
	local journal = require("mythic.journal")
	local name = table.concat(opts.fargs, " ")
	local ok, msg = journal.add_character(name)
	vim.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.WARN)
end, { nargs = "+" })

-- MythicCharacterList command
vim.api.nvim_create_user_command("MythicCharacterList", function()
	local journal = require("mythic.journal")
	require("mythic.list-window").show({
		title = "Characters",
		get_items = function()
			local items = {}
			for _, c in ipairs(journal.get_characters()) do
				table.insert(items, { label = c.name, count = c.count })
			end
			return items
		end,
		on_add = function(name) return journal.add_character(name) end,
		on_remove = function(idx) journal.remove_character(idx) end,
		on_duplicate = function(idx) return journal.duplicate_character(idx) end,
	})
end, { nargs = 0 })

-- MythicThreadAdd command
vim.api.nvim_create_user_command("MythicThreadAdd", function(opts)
	local journal = require("mythic.journal")
	local text = table.concat(opts.fargs, " ")
	local ok, msg = journal.add_thread(text)
	vim.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.WARN)
end, { nargs = "+" })

-- MythicThreadList command
vim.api.nvim_create_user_command("MythicThreadList", function()
	local journal = require("mythic.journal")
	require("mythic.list-window").show({
		title = "Threads",
		get_items = function()
			local items = {}
			for _, t in ipairs(journal.get_threads()) do
				table.insert(items, { label = t.text, count = t.count })
			end
			return items
		end,
		on_add = function(text) return journal.add_thread(text) end,
		on_remove = function(idx) journal.remove_thread(idx) end,
		on_duplicate = function(idx) return journal.duplicate_thread(idx) end,
	})
end, { nargs = 0 })

-- MythicCharacterRoll command (weighted random pick, result in floating window)
vim.api.nvim_create_user_command("MythicCharacterRoll", function()
	local journal = require("mythic.journal")
	local entry = journal.roll_character()
	if not entry then
		vim.notify("No characters in list", vim.log.levels.WARN)
		return
	end
	local result = "Character: " .. entry.name
	print(result)
	require("mythic.buffer").show(result)
end, { nargs = 0 })

-- MythicThreadRoll command (weighted random pick, result in floating window)
vim.api.nvim_create_user_command("MythicThreadRoll", function()
	local journal = require("mythic.journal")
	local entry = journal.roll_thread()
	if not entry then
		vim.notify("No threads in list", vim.log.levels.WARN)
		return
	end
	local result = "Thread: " .. entry.text
	print(result)
	require("mythic.buffer").show(result)
end, { nargs = 0 })
