local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local remotes = require(script.Parent.Parent.remotes)
local state = require(script.Parent.Parent.state)
local system_query_hook = require(script.Parent.Parent.system_query_hook)
local system_watch_hook = require(script.Parent.Parent.system_watch_hook)
local vide = require(script.Parent.Parent.Parent.vide)

local active = {}

local function pause_system(
	player: Player,
	scheduler_id: number,
	system_id: number
)
	assert(state.can_use_debugger(player), "cannot use debugger")

	local scheduler = state.schedulers()[scheduler_id]
	scheduler:pause(system_id)
end

local function resume_system(
	player: Player,
	scheduler_id: number,
	system_id: number
)
	assert(state.can_use_debugger(player), "cannot use debugger")

	local scheduler = state.schedulers()[scheduler_id]
	scheduler:resume(system_id)
end

local function get_system_performance_data(
	player: Player,
	scheduler_id: number,
	system_id: number,
	raw_scheduler_id: number
)
	assert(state.can_use_debugger(player), "cannot use debugger")

	local scheduler = state.schedulers()[scheduler_id]

	active[player] = active[player] or {}
	active[player][scheduler] = active[player][scheduler] or {}
	active[player][scheduler][system_id] = active[player][scheduler][system_id]
		or {
			connection = nil :: RBXScriptConnection?,
			disable = nil :: (() -> ())?,
			n = 0,
		}
	active[player][scheduler][system_id].n += 1

	assert(scheduler.systems[system_id])

	local system = scheduler.systems[system_id]
	local hook = system_query_hook.new(scheduler, system_id)

	local function get_packet()
		local queries = {}

		for _, view in hook.views() do
			table.insert(queries, {
				view.s,
				view.t,
				view.ent,
				view.includes,
				view.excludes,
				view.is_group,
			} :: { any })
		end

		return queries
	end

	if active[player][scheduler][system_id].n > 1 then
		return system.time.values, get_packet()
	end
	--print("creating new connection")

	active[player][scheduler][system_id].disable = hook:enable()
	active[player][scheduler][system_id].connection = RunService.Heartbeat:Connect(
		function()
			if scheduler:get_paused(system_id) then return end
			remotes.update_system_performance_data:FireClient(
				player,
				raw_scheduler_id,
				system_id,
				system.time.values[1],
				get_packet()
			)
		end
	)

	return system.time.values, get_packet()
end

local watches = {}
local watches_associated = {}
local id = 0
local function register_system_watch_data(player, scheduler_id: number, index)
	assert(state.can_use_debugger(player), "cannot use debugger")
	id += 1
	local id = id
	local local_scheduler = (state.all_schedulers :: any).entries[scheduler_id].index
	local scheduler = state.schedulers()[local_scheduler]
	local watch = system_watch_hook.new(scheduler, index)

	watches_associated[id] = player
	watches[id] = {
		watch = watch,
		disable = nil :: (() -> ())?,
		cleanup = vide.mount(function()
			local prev = 0
			vide.effect(function()
				local changes = watch.total_changes()
				if #changes == prev then return end
				prev = #changes

				task.spawn(
					function()
						remotes.update_system_watch_data:FireClient(
							player,
							scheduler_id,
							id,
							changes[#changes]
						)
					end
				)
			end)
		end),
	}

	return id
end

local function start_system_watch_data(player, id)
	assert(state.can_use_debugger(player), "cannot use debugger")

	local watch = watches[id]

	if watch.disable then watch.disable() end

	watch.disable = watch.watch:enable()
end

local function stop_system_watch_data(player, id)
	assert(state.can_use_debugger(player), "cannot use debugger")

	local watch = watches[id]

	print("disabled")

	if watch.disable then
		watch.disable()
		watch.disable = nil
	end
end

local function clear_system_watch_data(player, id)
	assert(state.can_use_debugger(player), "cannot use debugger")

	local watch = watches[id]

	if watch.disable then watch.disable() end

	watches[id] = nil
end

local function get_system_watch_logs(player, id, frame)
	assert(state.can_use_debugger(player), "cannot use debugger")

	local watch = watches[id]

	print(id, frame, watch.watch.frames()[frame])
	return watch.watch.frames()[frame]
end

local function disconnect_all(player: Player) active[player] = nil end

local function disconnect(player: Player, scheduler_id, system)
	assert(state.can_use_debugger(player), "cannot use debugger")
	--print("disconnected")

	local scheduler = state.schedulers()[scheduler_id]

	if scheduler == nil then return end

	active[player] = active[player] or {}
	active[player][scheduler] = active[player][scheduler] or {}
	active[player][scheduler][system] = active[player][scheduler][system]
		or {
			connection = nil :: RBXScriptConnection?,
			disable = nil :: (() -> ())?,
			n = 1,
		}

	local data = active[player][scheduler][system]
	data.n -= 1
	if data.n == 0 and data.connection and data.disable then
		data.connection:Disconnect()
		data.disable()
		active[player][scheduler][system] = nil
	end
end

Players.PlayerRemoving:Connect(disconnect_all)

return {

	disconnect = disconnect,
	get_system_performance_data = get_system_performance_data,

	pause_system = pause_system,
	resume_system = resume_system,

	register_system_watch_data = register_system_watch_data,
	start_system_watch_data = start_system_watch_data,
	stop_system_watch_data = stop_system_watch_data,
	clear_system_watch_data = clear_system_watch_data,
	get_system_watch_logs = get_system_watch_logs,
}
