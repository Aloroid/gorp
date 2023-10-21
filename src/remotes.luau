--[[

	A basic remote event wrapper to handle basic networking tasks.

	We opted to use a basic solution rather than a full one as it's much easier.

]]

local RunService = game:GetService("RunService")

type Event<T...> = {

	OnServerEvent: RBXScriptSignal<(Player, T...)>,
	OnClientEvent: RBXScriptSignal<T...>,

	FireServer: (any, T...) -> (),
	FireClient: (any, player: Player, T...) -> (),
}

type Function<T..., U...> = {

	OnServerInvoke: (Player: Player, T...) -> U...,

	InvokeServer: (any, T...) -> U...,
}

local function get_remote_event(name: string): any
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteEvent
			or (function()
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = script
				return remote
			end)()
	else
		return script:WaitForChild(name) :: RemoteEvent
	end
end

local function get_remote_function(name: string): any
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteFunction
			or (function()
				local remote = Instance.new("RemoteFunction")
				remote.Name = name
				remote.Parent = script
				return remote
			end)()
	else
		return script:WaitForChild(name) :: RemoteFunction
	end
end

return {

	check_if_permission = get_remote_function("check_if_permission") :: Function<(), (boolean)>,
	get_server_registries = get_remote_function("get_server_registries") :: Function<(), ({ string })>,
	get_server_cts = get_remote_function("get_server_cts") :: Function<(), ({ [string]: number })>,
	update_server_cts = get_remote_event("update_server_cts") :: Event<{ [string]: number }>,

	set_query = get_remote_function("set_query") :: Function<
		(number, number, string),
		({ number }, { { string } })
	>,
	query_changed = get_remote_event("query_changed") :: Event<number, { { any } }, { number }>,

	get_server_schedulers = get_remote_function("get_schedulers") :: Function<(), ({ string })>,
	subscribe_scheduler_data = get_remote_function("subscribe_scheduler") :: Function<(number), ({ string })>,
	unsubscribe_scheduler_data = get_remote_function("unsubscribe_scheduler") :: Function<(number)>,
	update_scheduler_data = get_remote_event("update_scheduler") :: Event<{ string }>,

	get_system_performance_data = get_remote_function("get_system_data") :: Function<
		(number, number),
		({ number }, { { any } })
	>,
	update_system_performance_data = get_remote_event(
		"update_system_performance_data"
	) :: Event<
		number,
		number,
		number,
		{ { any } }
	>,
	stop_flow_system_performance_data = get_remote_event(
		"stop_flow_system_performance"
	) :: Event<number, number>,

	get_all_entity_values = get_remote_function("get_all_entity_values") :: Function<
		(number, number),
		({ number }, { any })
	>,
	update_entities = get_remote_event("update_value") :: Event<number, { { any } }, { { any } }>,
}
