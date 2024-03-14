local Players = game:GetService("Players")

local gorp = require(script.Parent.Parent.Parent.gorp)
local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local server_state = require(script.Parent.Parent.server_state)

local unsubscribe_scheduler = queue(remotes.unsubscribe_scheduler)
local player_removing = queue(Players.PlayerRemoving)

local unique_subscription_id = 0
local active_subscriptions = {}
local associated_with = {}

--- Writes a bool to a buffer based on an index. This uses indexes starting from 1
local function write_bool_to_buffer(b: buffer, index: number, bool: boolean)
	buffer.writeu8(
		b,
		(index - 1) // 8,
		bit32.replace( -- calculates the new number by changing the bit of the current value
			buffer.readu8(b, (index - 1) // 8), -- reads the byte from the buffer
			bool and 1 or 0, -- coerces the bool to a number
			index - 1 - (index - 1) // 8 * 8 -- calculate the bit position
		)
	)
end

local function generate_update_callback(
	connector: remotes.connector,
	scheduler: gorp.Scheduler,
	subscription_id: number
)
	local target = reverse_connector(connector)

	local current_expected_data = {}
	local map_system_to_old_index = {}

	local function send_new_packet_to_client()
		debug.profilebegin("making new packet")

		local paused = buffer.create(math.ceil(#scheduler.system_order / 8))
		local times = buffer.create(#scheduler.system_order * 4)
		local changes: { { name: string, old: number, new: number } | { old: number } } = {}

		-- Generates the packet that we are going to send to the client.
		for index, system_index in scheduler.system_order do
			local system_name = scheduler.system_names[system_index]
			local is_paused = not not scheduler.system_paused[system_index] -- coerces it into bool
			local average_time = scheduler.system_data[system_index].average:average()

			-- Write the data to the buffers
			buffer.writef32(times, (index - 1) * 4, average_time)
			write_bool_to_buffer(paused, index, is_paused)

			if current_expected_data[index] == system_index then continue end
			local old_index = map_system_to_old_index[system_index]
			local packet = { name = system_name, old = old_index, new = index }
			table.insert(changes, packet)
		end

		-- compare lengths and remove them
		if #current_expected_data > #scheduler.system_order then
			for i = #scheduler.system_order + 1, #current_expected_data do
				local packet = { old = i }
				table.insert(changes, packet)
				map_system_to_old_index[current_expected_data[i]] = nil
			end
		end

		current_expected_data = table.clone(scheduler.system_order)

		for index, system in scheduler.system_order do
			map_system_to_old_index[system] = index
		end

		debug.profileend()

		remotes.replicate_scheduler:fire(target, subscription_id, {
			paused = paused,
			average_times = times,
			system_order_changes = changes,
		})
	end

	-- we return a function that you can call every frame
	return send_new_packet_to_client
end

local frame = 0

-- we put this outside the system in-case someone borks up and pauses replicate_scheduler
remotes.pause_system:connect(function(connector, scheduler_id: number, system_name: string, paused: boolean)
	local entry = server_state.schedulers[scheduler_id]

	if entry == nil then return end

	local index = table.find(entry.system_names, system_name)

	if index == nil then return end

	entry.system_paused[index] = if paused then true else nil :: any
end)

return function()
	frame += 1

	remotes.subscribe_scheduler:set_callback(function(connector, scheduler_id: number)
		-- attempt to find the registry. (might need to optimize this but whatever)
		local entry = server_state.schedulers[scheduler_id]

		if entry == nil then return -1 end

		unique_subscription_id += 1
		--print("created new subscription", unique_subscription_id, common_actor_id)
		active_subscriptions[unique_subscription_id] =
			generate_update_callback(connector, entry, unique_subscription_id)
		associated_with[unique_subscription_id] = connector

		return unique_subscription_id
	end)

	for connector, subscription_id in unsubscribe_scheduler:iter() do
		-- just nil the active query
		--print("stopped subscription", subscription_id)
		active_subscriptions[subscription_id] = nil
		associated_with[subscription_id] = nil
	end

	-- whenever a player leaves remove any remaining queries related to them
	for player in player_removing:iter() do
		for query_id, connector in associated_with do
			if connector.player ~= player then continue end
			associated_with[query_id] = nil
			active_subscriptions[query_id] = nil
		end
	end

	if frame % 3 ~= 0 then return end

	-- go through every active query and call it
	for query_id, update_callback in active_subscriptions do
		update_callback()
	end
end
