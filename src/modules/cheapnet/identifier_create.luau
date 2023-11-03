--[[

	Handles the creation of a new identifier.

]]

local RunService = game:GetService("RunService")

local efficient_pack_int = require(script.Parent.efficient_pack_int)
local get_identifier_namespace = require(script.Parent.get_identifier_namespace)
local identifier_state = require(script.Parent.identifier_state)

local remote_new: RemoteEvent
local remote_get_all: RemoteFunction

local function get_remote()
	if remote_new then return end

	if RunService:IsServer() then
		-- we use script:FindFirstChild in-case someone tries running this in parallel
		remote_new = (script:FindFirstChild("Receive") :: RemoteEvent)
			or Instance.new("RemoteEvent")
		remote_get_all = (script:FindFirstChild("GetAll") :: RemoteFunction)
			or Instance.new("RemoteFunction");

		(remote_new :: any).Name = "Receive"
		remote_get_all.Name = "GetAll";
		(remote_new :: any).Parent = script
		remote_get_all.Parent = script

		remote_get_all.OnServerInvoke = function(player)
			local namespaces = {}

			for key, namespace in identifier_state do
				namespaces[key] = namespace.values
			end

			return namespaces
		end
	else
		remote_new = script:WaitForChild("Receive") :: RemoteEvent
		remote_get_all = script:WaitForChild("GetAll") :: RemoteFunction

		task.spawn(function()
			local replicated_namespaces = remote_get_all:InvokeServer()

			for key, namespace_values in replicated_namespaces do
				local namespace = get_identifier_namespace(key)

				namespace.values = namespace_values
				namespace.size = #namespace_values

				for id, value in namespace_values do
					namespace.keys[value] = id

					if namespace.yielding[value] then
						-- resume every thread that was waiting for this identifier
						for _, thread in namespace.yielding[value] do
							coroutine.resume(
								thread,
								efficient_pack_int.pack(id, true)
							)
						end
						-- remove it since it now exists inside the namespace
						namespace.yielding[value] = nil
					end
				end

				identifier_state[key] = replicated_namespaces
			end
		end);

		(remote_new :: any).OnClientEvent:Connect(
			function(namespace_key: string, id_packed: string, value: any)
				local id = efficient_pack_int.unpack(id_packed, true)
				local namespace = get_identifier_namespace(namespace_key)
				namespace.size += 1
				namespace.keys[value] = id
				namespace.values[id] = value

				if namespace.yielding[value] then
					-- resume every thread that was waiting for this identifier
					for _, thread in namespace.yielding[value] do
						coroutine.resume(thread, id_packed)
					end
					-- remove it since it now exists inside the namespace
					namespace.yielding[value] = nil
				end
			end
		)
	end
end

local function replicate_value(namespace_key: string, id: number, value: any)
	get_remote()
	remote_new:FireAllClients(
		namespace_key,
		efficient_pack_int.pack(id, true),
		value
	)
end

local function identifier_create(
	namespace_key: string,
	value: any,
	yield: boolean?
): string
	local namespace = get_identifier_namespace(namespace_key)
	local key = namespace.keys[value]

	if key then return efficient_pack_int.pack(key, true) end

	if RunService:IsServer() then
		local id = namespace.size

		namespace.values[id] = value
		namespace.keys[value] = id

		namespace.size += 1

		replicate_value(namespace_key, id, value)

		return efficient_pack_int.pack(id, true)
	end

	assert(yield, "identifier does not exist")

	-- special value, this is only used inside client_event_bridge
	namespace.yielding[value] = namespace.yielding[value] or {}
	table.insert(namespace.yielding[value], coroutine.running())
	local id = coroutine.yield()

	return id
end

get_remote()

return identifier_create
