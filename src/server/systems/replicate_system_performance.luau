local Players = game:GetService("Players")

local common_actor_id = require(script.Parent.Parent.Parent.common_actor_id)
local generic_ecs_layer = require(script.Parent.Parent.Parent.generic_ecs_layer)
local gorp = require(script.Parent.Parent.Parent.gorp)
local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local server_state = require(script.Parent.Parent.server_state)

local unsubscribe_system = queue(remotes.unsubscribe_system)
local player_removing = queue(Players.PlayerRemoving)

local unique_subscription_id = 0
local active_subscriptions = {}
local cleanup_callbacks = {}
local associated_with = {}

local function generate_update_callback(
	connector: remotes.connector,
	scheduler: gorp.Scheduler,
	system_id: number,
	subscription_id: number
)
	local target = reverse_connector(connector)

	local label_threads = {}
	local pending_threads = {}
	local packets = {}

	for index, category in generic_ecs_layer.system_labels do
		local thread = coroutine.create(function()
			while true do
				coroutine.yield(category.capture(function()
					pending_threads[index] = coroutine.running()
					coroutine.yield()
				end))
			end
		end)

		label_threads[index] = thread
	end

	local cleanup_before_hook = scheduler:_hook_before(function(id)
		if system_id ~= id then return end

		pending_threads = {}

		for index, thread in label_threads do
			local ok, result = coroutine.resume(thread)

			if ok == false then
				label_threads[index] = nil
				warn(result)
			elseif not pending_threads[index] then
				packets[index] = result
			end
		end
	end)
	local cleanup_after_hook = scheduler:_hook_after(function(id)
		if system_id ~= id then return end

		for index, thread in pending_threads do
			local ok, result = coroutine.resume(thread)

			if ok == false then
				label_threads[index] = nil
				warn(result)
			else
				packets[index] = result
			end
		end
	end)

	cleanup_callbacks[subscription_id] = function()
		cleanup_before_hook()
		cleanup_after_hook()
	end

	local packet_frame = 0
	local function send_new_packet_to_client()
		debug.profilebegin("create system replication packet")

		local system = scheduler.system_data[system_id]
		if system.average:updated() == false then return end

		local latest_time = system.average.values[#system.average.values]
		
		local b = buffer.create(10)
		buffer.writeu32(b, 0, subscription_id)
		buffer.writeu16(b, 4, packet_frame)
		buffer.writef32(b, 6, latest_time)

		
		packet_frame += 1

		remotes.replicate_system_times:fire(target, b, packets)
		packets = {}
		debug.profileend()
	end

	-- we return a function that you can call every frame
	return send_new_packet_to_client
end

return function()
	remotes.subscribe_system:set_callback(function(connector, scheduler_id, system_name)
		local entry = server_state.schedulers[scheduler_id]
		if entry == nil then return -1 end
		local system_id = table.find(entry.system_names, system_name)
		if system_id == nil then return -1 end

		unique_subscription_id += 1
		--print("created new subscription", unique_subscription_id, common_actor_id)
		active_subscriptions[unique_subscription_id] =
			generate_update_callback(connector, entry, system_id, unique_subscription_id)
		associated_with[unique_subscription_id] = connector

		return unique_subscription_id
	end)

	for connector, subscription_id in unsubscribe_system:iter() do
		-- just nil the active query
		cleanup_callbacks[subscription_id]()
		--print("stopped subscription", subscription_id)

		active_subscriptions[subscription_id] = nil
		associated_with[subscription_id] = nil
		cleanup_callbacks[subscription_id] = nil
	end

	-- whenever a player leaves remove any remaining queries related to them
	for player in player_removing:iter() do
		for subscription_id, connector in associated_with do
			if connector.player ~= player then continue end
			cleanup_callbacks[subscription_id]()
			associated_with[subscription_id] = nil
			active_subscriptions[subscription_id] = nil
			cleanup_callbacks[subscription_id] = nil
		end
	end

	-- go through every active query and call it
	for query_id, update_callback in active_subscriptions do
		update_callback()
	end
end
