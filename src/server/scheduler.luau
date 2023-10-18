--[[
	Handles replication related to schedulers

]]

local Players = game:GetService("Players")

local remotes = require(script.Parent.Parent.remotes)
local state = require(script.Parent.Parent.state)

local subscribed = {}

local function subscribe_scheduler_data(player: Player, index: number)
	assert(state.can_use_debugger(player))
	subscribed[player] = subscribed[player] or {}

	local scheduler = state.schedulers()[index]
	assert(scheduler, "no scheduler with that index exists")

	local function get_packet()
		local values = {}

		for index, system in scheduler.systems do
			values[index] =
				string.pack("zf", system.name, system.time:average())
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
			remotes.update_scheduler_data:FireClient(player, get_packet())
		end
		subscribed[player][index] = nil
	end)

	return get_packet()
end

local function unsubscribe_scheduler_data(player: Player, index: number)
	assert(state.can_use_debugger(player))
	subscribed[player] = subscribed[player] or {}
	subscribed[player][index] -= 1
end

local function get_schedulers(player: Player)
	assert(state.can_use_debugger(player))

	local schedulers = {}

	for i, scheduler in state.schedulers() do
		table.insert(schedulers, scheduler.name)
	end

	return schedulers
end

Players.PlayerRemoving:Connect(function(player) subscribed[player] = nil end)

return {

	get_schedulers = get_schedulers,
	subscribe_scheduler_data = subscribe_scheduler_data,
	unsubscribe_scheduler_data = unsubscribe_scheduler_data,
}
