local cts = require(script.Parent.cts)
local ecr7 = require(script.Parent.Parent.modules.ecr7)
local registry = require(script.Parent.registry)
local servers = require(script.Parent.servers)

local function add_local_server(id: number, namespace: string)
	local ent = registry:create()

	registry:set(ent, cts.ActorId, id)
	registry:set(ent, cts.ReplicatedFrom, namespace)
	registry:set(ent, cts.ServerId, ecr7.context)

	print("created new server")

	servers["client"][id] = ent
end

return add_local_server
