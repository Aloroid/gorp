local cts = require(script.Parent.cts)
local registry = require(script.Parent.registry)
local rolling_average = require(script.Parent.Parent.modules.rolling_average)
local rts = require(script.Parent.Parent.rts)

local function new_scheduler(name: string, max: number?)
	max = max or 50
	assert(max)

	local self = {} :: rts.Scheduler
	local default_name = `Scheduler #{#registry:view(cts.Scheduler) + 1}`

	local entity = registry:create()
	local system_names: { [string]: rts.entity } = {}
	local systems_unused: { [rts.entity]: true } = {}
	local used_systems: { rts.entity } = {}

	registry:set(entity, cts.Name, name or default_name)
	registry:set(entity, cts.Scheduler, {})

	local i = 0
	-- Runs the given callback and benchmarks it.
	function self:system<T...>(name: string, callback: (T...) -> (), ...: T...)
		i += 1

		local system = system_names[name]

		if system == nil then
			local system_data = {

				index = i,

				before = {},
				after = {},
			}

			system = registry:create()

			registry:set(system, cts.Name, name)
			registry:set(system, cts.System, system_data)
			registry:set(system, cts.Average, rolling_average.new(max))
			registry:set(system, cts.Queries, {})

			system_names[name] = system
		end

		systems_unused[system] = nil
		table.insert(used_systems, system)

		local system_data = registry:get(system, cts.System)

		-- run the system if its not paused
		if not registry:has(system, cts.Paused) then
			for _, callback in system_data.before do
				callback(name)
			end

			-- we use xpcall, while we do have a internal no_yield module, i know
			-- someone who needs to be able to call task.synchronize and task.desynchronize
			-- so we'll just use xpcall
			local start = os.clock()
			local ok, err = xpcall(callback :: any, function(err) return debug.traceback(err, 2) end, ...)
			local finish = os.clock()

			for _, callback in system_data.after do
				callback(name)
			end

			if ok == false then warn(`{name} failed to run:\n{err}`) end

			local t = finish - start

			registry:get(system, cts.Average):add(t)
			registry:patch(system, cts.Average, function(v) return v end)
		end
	end

	function self:finish()
		i = 0

		local old_systems = registry:get(entity, cts.Scheduler)

		-- remove any unused systems
		for system in systems_unused do
			registry:destroy(system)
		end

		-- system order changed. check if it's the same, otherwise update.
		for i, system in used_systems do
			if old_systems[i] == system then continue end
			registry:set(entity, cts.Scheduler, used_systems)
			break
		end

		-- size is different
		if #used_systems ~= #old_systems then registry:set(entity, cts.Scheduler, used_systems) end

		-- create a list for the next iteration for unused systems
		for i, system in used_systems do
			systems_unused[system] = true
		end

		used_systems = {}
	end

	return self
end

return new_scheduler
