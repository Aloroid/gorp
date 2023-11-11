local cts = require(script.Parent.cts)
local registry = require(script.Parent.registry)
local server_ids = require(script.Parent.server_ids)

local function get_entity(
	actor_id: number,
	type: "client" | "server",
	server_id: number
)
	if server_ids[type][actor_id] and server_ids[type][actor_id][server_id] then
		return server_ids[type][actor_id][server_id]
	end

	local ent = registry:create()

	registry:set(ent, cts.ActorId, actor_id)
	registry:set(ent, cts.ReplicatedFrom, type)
	registry:set(ent, cts.ServerId, server_id)

	return ent
end

return get_entity
