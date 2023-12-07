--[[

	net is a utility library designed to handle connections to other actors and
	the server for me.

]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local common_actor_id = require(script.Parent.Parent.common_actor_id)
local traffic_check = require(script.Parent.traffic_check)

type namespace = "client" | "server"
export type connector = {
	namespace: namespace,
	to: number?,
	from: number?,
	player: Player?,
}

local function get_remote_event(name: string): RemoteEvent & { actor: BindableEvent }
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteEvent & { actor: BindableEvent }
			or (function()
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = script

				local fire_actor = Instance.new("BindableEvent")
				fire_actor.Name = "actor"
				fire_actor.Parent = remote
				return remote :: RemoteEvent & { actor: BindableEvent }
			end)()
	else
		return script:WaitForChild(name) :: RemoteEvent & { actor: BindableEvent }
	end
end

local function get_remote_function(name: string): RemoteFunction & {
	result: BindableEvent,
	actor: BindableEvent,
}
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteFunction & {
			result: BindableEvent,
			actor: BindableEvent,
		} or (function()
			local remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = script

			local bindable_event = Instance.new("BindableEvent")
			bindable_event.Name = "result"
			bindable_event.Parent = remote

			local fire_actor = Instance.new("BindableEvent")
			fire_actor.Name = "actor"
			fire_actor.Parent = remote
			return remote
		end)() :: RemoteFunction & {
			result: BindableEvent,
			actor: BindableEvent,
		}
	else
		return script:WaitForChild(name) :: RemoteFunction & {
			result: BindableEvent,
			actor: BindableEvent,
		}
	end
end

local function create_event(name: string, do_not_block_traffic: boolean?)
	local remote = get_remote_event(name)
	local event = {
		type = "event",
	}

	function event:fire(connector: connector, ...)
		local server_to_server = RunService:IsServer() and connector.namespace == "server"
		local client_to_client = RunService:IsClient() and connector.namespace ~= "server"

		if client_to_client or server_to_server then
			connector.player = connector.player or Players.LocalPlayer
			connector.from = common_actor_id
			remote.actor:Fire(connector, ...)
			print("fired", name, "by", connector.from)
		else
			if RunService:IsServer() then
				assert(connector.player, "no player specified")
				connector.from = common_actor_id
				remote:FireClient(connector.player, connector, ...)
			else
				connector.from = common_actor_id
				remote:FireServer(connector, ...)
			end
		end
	end

	function event:connect(callback: (connector: connector, ...any) -> ())
		return remote.actor.Event:Connect(function(connector: connector, ...)
			if
				connector.to ~= common_actor_id and connector.to ~= nil
				or RunService:IsServer() and connector.namespace ~= "server"
			then
				print("ignored packet meant for", connector)
				return
			end

			callback(connector, ...)
		end)
	end

	if RunService:IsServer() then
		-- block all traffic from unverified players
		remote.OnServerEvent:Connect(function(player: Player, connector: connector, ...)
			assert(
				do_not_block_traffic == true or traffic_check.check_player(player),
				`{player} tried to fire gorp server`
			)
			assert(connector.namespace == "server")

			connector.player = player
			print("received packet")

			remote.actor:Fire(connector, ...)
		end)
	else
		remote.OnClientEvent:Connect(function(connector, ...)
			connector.player = nil
			remote.actor:Fire(connector, ...)
		end)
	end

	return event
end

local function create_callback(name: string, do_not_block_traffic: boolean?)
	local remote = get_remote_function(name)
	local event = {
		type = "event",
	}

	local id = 0
	local current_callback = function(...) error("did not specify callback") end

	function event:invoke(connector: connector, ...)
		assert(connector.to, "this function requires a target to send to")

		local server_to_server = RunService:IsServer() and connector.namespace == "server"
		local client_to_client = RunService:IsClient() and connector.namespace ~= "server"

		if client_to_client or server_to_server then
			id += 1
			local stored = id

			local t
			local connection = remote.result.Event:Connect(function(from: number, to: number, id: number, ...)
				if from ~= connector.to then return end
				if to ~= common_actor_id then return end
				if id ~= stored then return end

				t = { ... }
			end)

			connector.from = connector.from or common_actor_id
			remote.actor:Fire(connector, common_actor_id, stored, ...)

			-- coroutine.yield breaks stuff
			while t == nil do
				task.wait()
			end

			connection:Disconnect()

			return unpack(t)
		else
			if RunService:IsServer() then
				error("unsecure")
			else
				connector.from = common_actor_id
				return remote:InvokeServer(connector, ...)
			end
		end
	end

	function event:set_callback(callback: (connector: connector, ...any) -> ...any) current_callback = callback end

	if RunService:IsServer() then
		remote.OnServerInvoke = function(player, connector, ...)
			assert(
				do_not_block_traffic == true or traffic_check.check_player(player),
				`{player} tried to invoke gorp server`
			)

			connector.player = player

			return event:invoke(connector, ...)
		end
		-- not specifying OnClientInvoke for security reasons
	end

	remote.actor.Event:Connect(function(connector: connector, actor: number, id: number, ...)
		local results = { current_callback(connector, ...) }
		connector.from = common_actor_id
		remote.result:Fire(common_actor_id, actor, id, unpack(results))
	end)

	return event
end

return {

	create_callback = create_callback,
	create_event = create_event,
}
