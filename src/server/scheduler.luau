local events = require(script.Parent.events)
local gorp = require(script.Parent.Parent.gorp)
local rolling_average = require(script.Parent.Parent.modules.rolling_average)
local server_state = require(script.Parent.server_state)

local function new_scheduler(scheduler_name: string, max: number?)
	max = max or 50
	assert(max)

	local default_name = `Scheduler #{#server_state.schedulers + 1}`

	local id_counter = 0
	local associated_names: { [gorp.system]: string } = {}
	local system_names: { [string]: gorp.system } = {}
	local systems_unused: { [gorp.system]: true } = {}
	local system_paused: { [gorp.system]: true } = {}
	local system_data: {
		[gorp.system]: {
			index: number,
			average: gorp.RollingAverage,
			before: { (name: string) -> () },
			after: { (name: string) -> () },
		},
	} =
		{}
	local used_systems: { gorp.system } = {}
	local old_used_systems = {}

	local self = {

		name = scheduler_name or default_name,

		system_names = associated_names,
		system_paused = system_paused,
		system_order = used_systems,
		system_data = system_data,

		updated_order = false,
	} :: gorp.Scheduler

	local function create_system(name: string, index: number)
		id_counter += 1
		local system_id = id_counter

		system_names[name] = system_id
		associated_names[system_id] = name
		system_data[system_id] = {

			index = index,

			average = rolling_average.new(50),

			before = {},
			after = {},
		}

		return system_id
	end

	local i = 0
	-- Runs the given callback and benchmarks it.
	function self:system<T...>(name: string, callback: (T...) -> (), ...: T...)
		i += 1

		local system_id = system_names[name]

		if system_id == nil then
			system_id = create_system(name, i)
		else
			task.spawn(
				assert,
				systems_unused[system_id],
				`attempted to run system "{name}" twice. make sure each system has a unique name!`
			)
			if not systems_unused[system_id] then return end
		end

		systems_unused[system_id] = nil
		table.insert(used_systems, system_id)

		-- run the system if its not paused
		if not system_paused[system_id] then
			local data = system_data[system_id]

			for _, callback in data.before do
				callback(name)
			end

			-- we use xpcall, while we do have a internal no_yield module, i know
			-- someone who needs to be able to call task.synchronize and task.desynchronize
			-- so we'll just use xpcall
			local start = os.clock()
			local ok, err = xpcall(callback :: any, function(err)
				return debug.traceback(err, 2)
			end, ...)
			local finish = os.clock()

			for _, callback in data.after do
				callback(name)
			end

			if ok == false then warn(`{name} failed to run:\n{err}`) end

			local t = finish - start

			data.average:add(t)
		end
	end

	function self:skip(name: string)
		local system = system_names[name]

		if system == nil then
			create_system(name, i)
		else
			task.spawn(
				assert,
				table.find(used_systems, system) == nil,
				`attempted to skip system "{name}" when it already ran. make sure each system has a unique name!`
			)
			return
		end

		print("skipped", name)
		systems_unused[system] = nil
		table.insert(used_systems, system)
	end

	function self:finish()
		i = 0

		-- remove any unused systems
		for system in systems_unused do
			local name = associated_names[system]

			system_names[name] = nil
			systems_unused[system] = nil
			system_data[system] = nil
			associated_names[system] = nil
		end

		-- system order changed. check if it's the same, otherwise update.
		for i, system in used_systems do
			if old_used_systems[i] == system then continue end
			self.updated_order = true
			break
		end

		-- size is different
		if #used_systems ~= #old_used_systems then self.updated_order = true end

		-- create a list for the next iteration for unused systems
		for i, system in used_systems do
			systems_unused[system] = true
		end

		old_used_systems = used_systems
		used_systems = {}
	end

	events.scheduler_created:fire(self)
	table.insert(server_state.schedulers, self)

	return self
end

return new_scheduler
