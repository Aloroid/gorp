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

export type NetEvent<T...> = {

	type: "event",

	fire: (any, connector: connector, T...) -> (),
	connect: (any, callback: (connector: connector, T...) -> ()) -> RBXScriptConnection,
}

export type NetCallback<T..., U...> = {

	type: "callback",

	invoke: (any, connector: connector, T...) -> U...,
	set_callback: (any, callback: (connector: connector, T...) -> U...) -> (),
}

local function get_remote_event(name: string, unreliable: boolean?): RemoteEvent & { actor: BindableEvent }
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteEvent & { actor: BindableEvent }
			or (function()
				local remote = Instance.new(if unreliable then "UnreliableRemoteEvent" else "RemoteEvent")
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

local function create_event<T...>(name: string, unreliable: boolean?, do_not_block_traffic: boolean?): NetEvent<T...>
	local remote = get_remote_event(name, unreliable)
	local event = {
		type = "event",
	} :: NetEvent<T...>

	function event:fire(connector: connector, ...)
		local server_to_server = RunService:IsServer() and connector.namespace == "server"
		local client_to_client = RunService:IsClient() and connector.namespace == "client"

		--print("firing", name, "to", connector.namespace, connector.to, client_to_client, common_actor_id)

		if client_to_client or server_to_server then
			connector = table.clone(connector)
			connector.player = connector.player or Players.LocalPlayer
			connector.from = common_actor_id
			remote.actor:Fire(connector, ...)
		else
			if RunService:IsServer() then
				assert(connector.player, "no player specified")
				local target = connector.player

				connector = table.clone(connector)

				connector.from = common_actor_id
				connector.player = nil
				remote:FireClient(target, connector, ...)
			else
				connector = table.clone(connector)
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
				--print("ignored packet meant for", connector)
				return
			end
			assert(
				do_not_block_traffic == true or traffic_check.check_player(Players.LocalPlayer),
				`{Players.LocalPlayer} tried to fire gorp server`
			)

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

			remote.actor:Fire(connector, ...)
		end)
	else
		remote.OnClientEvent:Connect(function(connector, ...)
			remote.actor:Fire(connector, ...)
		end)
	end

	return event
end

local function create_callback<T..., U...>(name: string, do_not_block_traffic: boolean?): NetCallback<T..., U...>
	local remote = get_remote_function(name)
	local callback = {
		type = "callback",
	} :: NetCallback<T..., U...>

	local id = 0
	local current_callback = function(...)
		error("did not specify callback")
	end

	function callback:invoke(connector: connector, ...: T...): U...
		assert(connector.to, "this function requires a target to send to")

		local server_to_server = RunService:IsServer() and connector.namespace == "server"
		local client_to_client = RunService:IsClient() and connector.namespace == "client"

		assert(
			do_not_block_traffic == true or traffic_check.check_player(Players.LocalPlayer),
			`{Players.LocalPlayer} tried to fire gorp server`
		)
		assert(connector.to, "there must be a target connector")

		connector = table.clone(connector)
		if client_to_client or server_to_server then
			--print("local invoke", name)
			id += 1
			local stored = id

			local t
			local connection = remote.result.Event:Connect(function(from: number, to: number, id: number, ...)
				--print(from, to, id, connector.to, common_actor_id, stored)
				if from ~= connector.to then return end
				if to ~= common_actor_id then return end
				if id ~= stored then return end

				--print("received", name)
				t = { ... }
			end)

			connector.from = connector.from or common_actor_id
			connector.player = connector.player or Players.LocalPlayer
			remote.actor:Fire(connector, common_actor_id, stored, ...)

			-- coroutine.yield breaks stuff
			while t == nil do
				task.wait()
			end

			--print("finished")
			connection:Disconnect()

			return unpack(t)
		else
			if RunService:IsServer() then
				error("unsecure")
			else
				--print("invoking server", name)
				connector.from = common_actor_id
				local results = { remote:InvokeServer(connector, ...) }
				--print("received results", name)
				return unpack(results)
			end
		end
	end

	function callback:set_callback(callback: (connector: connector, T...) -> U...)
		current_callback = callback :: any
	end

	if RunService:IsServer() then
		remote.OnServerInvoke = function(player, connector, ...)
			assert(
				do_not_block_traffic == true or traffic_check.check_player(player),
				`{player} tried to invoke gorp server`
			)

			connector.player = player

			--print("invoking server for client", name, player)
			local results = { callback:invoke(connector, ...) }
			--print("received results for", name)
			return unpack(results)
		end
		-- not specifying OnClientInvoke for security reasons
	end

	remote.actor.Event:Connect(function(connector: connector, origin: number, id: number, ...)
		if connector.to ~= common_actor_id then return end

		local results = { current_callback(connector, ...) }
		connector.from = common_actor_id
		remote.result:Fire(common_actor_id, origin, id, unpack(results))
	end)

	return callback
end

return {

	create_callback = create_callback,
	create_event = create_event,
}
