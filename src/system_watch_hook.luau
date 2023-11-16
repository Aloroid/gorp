--!optimize 2
--!native
--[[

	Hooks onto a system in search for changes that they make

]]

local rts = require(script.Parent.rts)
local state = require(script.Parent.state)
local vide = require(script.Parent.Parent.vide)

local system_watch_hook = {}

local source = vide.source

local function new_hook(scheduler: rts.Scheduler, index: number)
	local frames = source({})
	local changes = source({})
	local recording = source(true)
	local logs = {} :: { { any } }
	--local total_frames = source(0)
	local total_logs = 0

	local connections = {} :: { rts.Connection }

	for _, entry in state.worlds() do
		local world: rts.Registry = entry.world :: any
		for ctype, name in state.cts.ids() do
			local function log(type: number)
				return function(ent, value)
					total_logs += 1
					table.insert(logs, { type, ent, ctype, value :: any })
				end
			end

			table.insert(connections, world:added(ctype):connect(log(1)))
			table.insert(connections, world:changed(ctype):connect(log(2)))
			table.insert(connections, world:removing(ctype):connect(log(3)))
		end
	end

	-- disconnect all of the connections
	local function disconnect_all()
		for _, connection in connections do
			connection:disconnect()
		end
	end

	-- reconnects all of the connections
	local function reconnect_all()
		for _, connection in connections do
			connection:reconnect()
		end
	end

	disconnect_all()

	local cleanup_before
	local cleanup_after
	local enabled = {}

	-- force disables the watch
	local function force_disable()
		cleanup_before()
		cleanup_after()

		table.clear(enabled)
	end

	local function setup_hooks()
		cleanup_before = scheduler:_hook_before_system(index, function()
			logs = {}
			reconnect_all()
		end)
		cleanup_after = scheduler:_hook_after_system(index, function()
			disconnect_all()

			table.insert(changes(), total_logs)
			changes(changes())

			if #logs > 0 then
				table.insert(frames(), logs)
				frames(frames())
				print("recorded frame", #frames())
				logs = {}
				total_logs = 0
			end

			--total_frames(total_frames() + 1)

			if #frames() >= 1000 then force_disable() end
		end)
	end

	local self = {
		scheduler = scheduler,
		system = index,

		frames = frames,
		total_changes = changes,
		recording = recording,
	}

	function self:enable()
		local function disable()
			enabled[disable] = nil
			if next(enabled) == nil then
				cleanup_before()
				cleanup_after()
			end
		end

		logs = {}
		changes({})
		frames({})

		if next(enabled) == nil then setup_hooks() end

		enabled[disable] = true
		return disable
	end

	return self
end

type Hook = typeof(new_hook({} :: any, 1))

function system_watch_hook.new(
	scheduler: rts.Scheduler,
	index: number
): Hook
	return new_hook(scheduler, index)
end

return system_watch_hook
