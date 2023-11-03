local Players = game:GetService("Players")

local signal = require(script.Parent.Parent.signal)
local timestamps = {}

local function add_timestamp(player: Player)
	timestamps[player] = workspace:GetServerTimeNow()
end

local function remove_timestamp(player: Player)
	task.defer(function() timestamps[player] = nil end)
end

local stored = 0
local function get_timestamp() return stored end

local function set_timestamp(timestamp: number) stored = timestamp end

Players.PlayerAdded:Connect(add_timestamp)
Players.PlayerRemoving:Connect(remove_timestamp)

type Errors = "INVALID_TIMESTAMP" | "TOO_MANY_EVENTS" | "TOO_MANY_PACKETS"

return {

	timestamps = timestamps,

	get_timestamp = get_timestamp,
	set_timestamp = set_timestamp,

	invalid_timestamp = signal() :: signal.Signal<Player, Errors> & {
		fire: (signal.Signal<Player, Errors>, Player, Errors) -> (),
	},
}
