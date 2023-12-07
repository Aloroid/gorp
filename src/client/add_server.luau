local cts = require(script.Parent.cts)
local ecr7 = require(script.Parent.Parent.modules.ecr7)
local registry = require(script.Parent.registry)
local servers = require(script.Parent.servers)

local function add_local_server(id: number, namespace: string)
	if servers[namespace][id] then return end
	local ent = registry:create()

	registry:set(ent, cts.ActorId, id)
	registry:set(ent, cts.ReplicatedFrom, namespace)
	registry:set(ent, cts.ServerId, ecr7.context)

	servers[namespace][id] = ent

	print("created new server for", id, namespace, servers)
end

return add_local_server
