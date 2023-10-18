--[[

	used to hook into schedulers.
	this allows us to display data about what each system is performing.

]]

local rolling_average = require(script.Parent.rolling_average)
local state = require(script.Parent.state)

local scheduler = {}

local total = 0
function scheduler.new(scheduler_name: string?)
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

		begin = os.clock()
		name = given_name

		systems[i] = systems[i]
			or { time = rolling_average.new(), name = given_name }

		for callback in before do
			callback()
		end
	end

	-- this should be called after a system runs.
	-- we'll automatically infer context based on the first call.
	function self:after()
		for callback in after do
			callback()
		end

		systems[i].time:add(os.clock() - begin)
		systems[i].name = name
	end

	function self:finish() i = 0 end

	-- internal

	--
	function self:_hook_before(callback: () -> ())
		before[callback] = true

		return function() before[callback] = nil end
	end

	function self:_hook_after(callback: () -> ())
		after[callback] = true

		return function() after[callback] = nil end
	end

	-- add the scheduler to the state
	local schedulers = state.schedulers()
	table.insert(schedulers, self)
	state.schedulers(schedulers)

	return self
end

return scheduler
