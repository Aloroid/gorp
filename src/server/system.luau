local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local remotes = require(script.Parent.Parent.remotes)
local state = require(script.Parent.Parent.state)
local system_query_hook = require(script.Parent.Parent.system_query_hook)

local active = {}

local function get_system_performance_data(
	player: Player,
	scheduler_id: number,
	system_id: number
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
			remotes.update_system_performance_data:FireClient(
				player,
				scheduler_id,
				system_id,
				system.time.values[1],
				get_packet()
			)
		end
	)

	return system.time.values, get_packet()
end

local function disconnect_all(player: Player) active[player] = nil end

local function disconnect(player: Player, scheduler_id, system)
	assert(state.can_use_debugger(player), "cannot use debugger")
	--print("disconnected")

	local scheduler = state.schedulers()[scheduler_id]

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
}
