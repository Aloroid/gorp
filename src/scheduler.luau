local RunService = game:GetService("RunService")
--[[

	used to hook into schedulers.
	this allows us to display data about what each system is performing.

]]

local no_yield = require(script.Parent.no_yield)
local rolling_average = require(script.Parent.rolling_average)
local state = require(script.Parent.state)

local scheduler = {}

local total = 0
function scheduler.new(scheduler_name: string?, hide: boolean?, max: number?)
	local systems = {}
	total += 1

	local self = {
		name = scheduler_name or `Scheduler #{total}`,
		systems = systems,
	}

	-- we provide hooks so that we can run stuff before and after the system.
	-- this is usually stuff like creating connections and measuring performance
	local begin, name
	local i = 0
	local before = {} :: { [() -> ()]: true }
	local after = {} :: { [() -> ()]: true }

	-- this should be called before a systemr runs.
	function self:before(given_name: string)
		i += 1

		name = given_name

		systems[i] = systems[i]
			or {
				time = rolling_average.new(max),
				name = given_name,

				_before = {} :: { [() -> ()]: true },
				_after = {} :: { [() -> ()]: true },
			}

		for callback in before do
			callback()
		end

		for callback in systems[i]._before do
			callback()
		end
		begin = os.clock()
	end

	function self:system<T...>(name: string, system: (T...) -> (), ...: T...)
		self:before(name)
		local ok, thread, err = no_yield(system, ...)
		self:after()

		if ok == false and thread and err then
			warn("system failed:", debug.traceback(thread, err))
		end
	end

	function self:skip<T...>(name: string)
		i += 1
		systems[i] = systems[i]
			or {
				time = rolling_average.new(max),
				name = name,
				_before = {} :: { [() -> ()]: true },
				_after = {} :: { [() -> ()]: true },
			}
		systems[i].name = name
	end

	-- this should be called after a system runs.
	-- we'll automatically infer context based on the first call.
	function self:after(_custom_time: number?)
		systems[i].time:add(_custom_time or os.clock() - begin)
		for callback in after do
			callback()
		end

		for callback in systems[i]._after do
			callback()
		end

		systems[i].name = name
	end

	function self:finish() i = 0 end

	-- internal

	--
	function self:_hook_before_system(
		index: number,
		callback: () -> (),
		cleanup: (() -> ())?
	)
		local before_system = systems[index]._before
		before_system[callback] = true

		return function()
			if cleanup then cleanup() end
			before_system[callback] = nil
		end
	end

	function self:_hook_after_system(
		index: number,
		callback: () -> (),
		cleanup: (() -> ())?
	)
		local after_system = systems[index]._after
		after_system[callback] = true

		return function()
			if cleanup then cleanup() end
			after_system[callback] = nil
		end
	end

	-- add the scheduler to the state
	if hide then return self end

	local schedulers = state.schedulers()
	table.insert(schedulers, self)
	state.schedulers(schedulers)

	if RunService:IsServer() then
		local index = #schedulers
		local id = SharedTable.increment(state.all_schedulers, "size", 1)

		if scheduler_name == nil then self.name = `Scheduler #{id}` end

		SharedTable.update(
			state.all_schedulers.entries,
			id,
			function()
				return {
					name = self.name,
					index = index,
					actor = state.actor_id,
				}
			end
		)
	end

	return self
end

return scheduler
