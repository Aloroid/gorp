local cts = require(script.Parent.cts)
local registry = require(script.Parent.registry)

local server_ids = {
	client = {},
	server = {},
}

registry:on_add(cts.ServerId):connect(function(ent, server_id)
	local actor_id, from = registry:get(ent, cts.ActorId, cts.ReplicatedFrom)

	server_ids[from][actor_id] = server_ids[from][actor_id] or {}
	server_ids[from][actor_id][server_id] = ent
end)

registry:on_remove(cts.ServerId):connect(function(ent)
	local actor_id, server_id, from = registry:get(ent, cts.ActorId, cts.ServerId, cts.ReplicatedFrom)

	server_ids[from][actor_id] = server_ids[from][actor_id] or {}
	server_ids[from][actor_id][server_id] = nil
end)

return server_ids
