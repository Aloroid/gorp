--!optimize 2
--!native
--[[

	Hooks onto a system in search for queries

]]

local rts = require(script.Parent.rts)
local state = require(script.Parent.state)
local vide = require(script.Parent.Parent.vide)

local system_query_hook = {}
local cached = {}

local source = vide.source

local function new_hook(scheduler: rts.Scheduler, index: number)
	local view_calls = {}
	local views = source({} :: {
		{
			includes: { number },
			excludes: { number }?,
			ent: number,
			s: number,
			t: number,
			is_group: true?,
		}
	})
	local max = 0
	local iterating_groups = {}
	local new_views = {}

	local cleanup_before = scheduler:_hook_before_system(index, function()
		view_calls = {}
		iterating_groups = {}

		state.iterating_groups = iterating_groups

		for _, entry in state.worlds() do
			-- cant modify ecr
			if table.isfrozen(entry.world) then continue end

			local world = entry.world
			local view_call = world.view
			view_calls[world] = view_call

			function world:view(...)
				local view = view_call(self, ...) :: any

				view.s = 0
				view.t = 0
				view.ent = 0

				max += 1
				new_views[max] = view

				-- modify the metatable so that __iter will be benchmarked
				local mt = getmetatable(view)
				local iter = mt.__iter

				function mt.__iter(self)
					local iterator = iter(self)
					local begin = os.clock()
					return function()
						local start = os.clock()
						local a, b, c, d, e, f, g, h, j, k = iterator()
						local finish = os.clock()
						view.s += finish - start
						view.t += finish - begin
						begin = finish
						view.ent += if a then 1 else 0
						return a, b, c, d, e, f, g, h, j, k
					end
				end

				return view
			end
		end
	end, function()
		for world, view in view_calls do
			world.view = view
		end
		state.iterating_groups = nil
		table.clear(view_calls)
	end)
	local cleanup_after = scheduler:_hook_after_system(index, function()
		for _, entry in state.worlds() do
			-- cant modify ecr
			if table.isfrozen(entry.world) then continue end

			local world = entry.world
			world.view = view_calls[world]
		end

		state.iterating_groups = nil
		table.clear(view_calls)

		-- insert groups
		for i, group in iterating_groups do
			new_views[max + i] = group :: any
		end

		views(new_views)
		max = 0
	end)

	local enabled = {}
	local self = {
		scheduler = scheduler,
		system = index,
		views = views,
	}
	function self:enable()
		local function disable()
			enabled[disable] = nil
			if next(enabled) == nil then
				cached[scheduler][index] = nil
				cleanup_before()
				cleanup_after()
			end
		end
		enabled[disable] = true
		return disable
	end

	cached[scheduler][index] = self
	return self
end

type Hook = typeof(new_hook({} :: any, 1))

function system_query_hook.new(scheduler: rts.Scheduler, index: number): Hook
	cached[scheduler] = cached[scheduler] or {}
	if cached[scheduler][index] then
		local self = cached[scheduler][index]
		return self
	end

	return new_hook(scheduler, index)
end

return system_query_hook
