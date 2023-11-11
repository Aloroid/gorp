local cts = require(script.Parent.cts)
local events = require(script.Parent.Parent.events)
local general_replication = require(script.Parent.general_replication)
local registry = require(script.Parent.registry)
local servers = require(script.Parent.servers)

local function add_local_server(
	id: number,
	components: { [string]: number }, -- the server components
	context_id: number
)
	local ent = registry:create()
	local true_cts = {}

	print("added server id", id)

	for name, ctype in components do
		local true_ctype = cts[name]
		true_cts[ctype] = true_ctype
	end

	registry:set(ent, cts.ActorId, id)
	registry:set(ent, cts.ReplicatedFrom, "client")
	registry:set(ent, cts.ServerId, context_id)
	registry:set(ent, cts.ServerComponents, true_cts)

	servers["client"][id] = ent

	print("created values", true_cts)

	local ent, val = events.get_initial_state:Invoke(id)
	print("invoked", ent, val)
	general_replication(id, "client", ent, val, {}, {})
end

return add_local_server
