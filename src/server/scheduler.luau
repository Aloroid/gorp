--[[
	Handles replication related to schedulers

]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local remotes = require(script.Parent.Parent.remotes)
local state = require(script.Parent.Parent.state)

local subscribed = {}

local function subscribe_scheduler_data(
	player: Player,
	index: number,
	s_index: number
)
	assert(state.can_use_debugger(player))
	subscribed[player] = subscribed[player] or {}

	local scheduler = state.schedulers()[index]
	assert(scheduler, "no scheduler with that index exists")

	local function get_packet()
		local values = {}

		for index, system in scheduler.systems do
			values[index] = string.pack(
				"zfB",
				system.name,
				system.time:average(),
				if scheduler:get_paused(index) then 255 else 0
			)
		end

		return values
	end

	if subscribed[player][index] then
		subscribed[player][index] += 1
		return get_packet()
	end

	subscribed[player][index] = 1

	task.spawn(function()
		while
			task.wait(1 / 20)
			and subscribed[player]
			and subscribed[player][index] > 0
		do
			remotes.update_scheduler_data:FireClient(
				player,
				s_index,
				get_packet()
			)
		end
		if subscribed[player] == nil then return end
		subscribed[player][index] = nil
	end)

	return get_packet()
end

local function unsubscribe_scheduler_data(player: Player, index: number)
	assert(state.can_use_debugger(player))
	subscribed[player] = subscribed[player] or {}
	subscribed[player][index] -= 1
end

local players_receiving = {}

local function get_schedulers(player: Player)
	if not state.can_use_debugger(player) then return {} end
	players_receiving[player] = true

	local schedulers = {}

	for i, scheduler in state.all_schedulers.entries :: any do
		table.insert(schedulers, scheduler.name)
	end

	return schedulers
end

local old_size = state.all_schedulers.size
RunService.Heartbeat:Connect(function()
	if old_size == state.all_schedulers.size then return end

	local schedulers = {}

	for i, scheduler in state.all_schedulers.entries :: any do
		table.insert(schedulers, scheduler.name)
	end

	for player in players_receiving do
		remotes.updated_server_schedulers:FireClient(player, schedulers)
	end

	old_size = state.all_schedulers.size
end)

Players.PlayerRemoving:Connect(function(player)
	subscribed[player] = nil
	players_receiving[player] = nil
end)

return {

	get_schedulers = get_schedulers,
	subscribe_scheduler_data = subscribe_scheduler_data,
	unsubscribe_scheduler_data = unsubscribe_scheduler_data,
}
