--!native
--!optimize 2
--[[

	Stores all the groups inside a weak table.

]]

local rts = require(script.Parent.rts)
local state = require(script.Parent.state)

local function hook(registry: rts.Registry)
	if table.isfrozen(registry) then return end -- registry does not support
	-- run table.clone

	local group = registry.group

	function registry.group(self, ...)
		local created_group = group(self, ...)
		local ctypes = { ... }

		local mt = getmetatable(created_group)
		local iter = mt.__iter

		function mt.__iter()
			if state.iterating_groups == nil then return iter(created_group) end
			local iterator = iter(created_group)
			local performance_data = {
				s = 0,
				t = 0,
				ent = 0,
				includes = ctypes,
				is_group = true,
			}

			table.insert(state.iterating_groups, performance_data :: any)
			local begin = os.clock()

			return function()
				local start = os.clock()
				local a, b, c, d, e, f, g, h, i, j, k, l, m = (iterator :: any)()
				local finish = os.clock()
				performance_data.s += finish - start
				performance_data.t += finish - begin
				begin = finish
				performance_data.ent += 1
				return a, b, c, d, e, f, g, h, i, j, k, l, m
			end
		end

		return created_group
	end
end

return hook
