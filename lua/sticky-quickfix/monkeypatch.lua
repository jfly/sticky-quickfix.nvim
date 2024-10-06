local og_setqflist = nil

local function compare_distance(distance1, distance2)
	local lines_delta1, cols_delta1 = unpack(distance1)
	local lines_delta2, cols_delta2 = unpack(distance2)

	if lines_delta1 < lines_delta2 then
		return -1
	elseif lines_delta1 > lines_delta2 then
		return 1
	else
		if cols_delta1 < cols_delta2 then
			return -1
		elseif cols_delta1 > cols_delta2 then
			return 1
		else
			return 0
		end
	end
end

local function select_nearest_quickfix_entry(fallback_idx)
	local current_buf = vim.api.nvim_get_current_buf()
	local current_line, current_col = unpack(vim.api.nvim_win_get_cursor(0))

	local qf_list = vim.fn.getqflist()

	local nearest_entry_idx = nil
	local nearest_entry_distance = { math.huge, math.huge }

	for idx, entry in ipairs(qf_list) do
		if entry.bufnr == current_buf then
			local lines_delta = math.abs(entry.lnum - current_line)
			local cols_delta = math.abs((entry.col or 1) - current_col)
			local distance = { lines_delta, cols_delta }

			-- Update the nearest entry if this one is closer.
			if compare_distance(distance, nearest_entry_distance) < 0 then
				nearest_entry_distance = distance
				nearest_entry_idx = idx
			end
		end
	end

	if nearest_entry_idx then
		-- If we found an entry near the current cursor position, use it.
		og_setqflist({}, "r", { idx = nearest_entry_idx })
	else
		-- Otherwise, fallback to the given fallback_idx.
		og_setqflist({}, "r", { idx = fallback_idx })
	end
end

return {
	start = function()
		if og_setqflist then
			-- Looks like we're already active! Nothing to do.
			return
		end

		og_setqflist = vim.fn.setqflist

		vim.fn.setqflist = function(...)
			local qf_idx = vim.fn.getqflist({ idx = 0 }).idx

			local ret_val = og_setqflist(...)

			select_nearest_quickfix_entry(qf_idx)

			return ret_val
		end
	end,
	stop = function()
		vim.fn.setqflist = og_setqflist
		og_setqflist = nil
	end,
}
