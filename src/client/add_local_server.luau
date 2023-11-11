local cts = require(script.Parent.cts)
local get_entity = require(script.Parent.get_entity)
local registry = require(script.Parent.registry)
local servers = require(script.Parent.servers)

local function add_local_server(
	id: number,
	components: { [string]: number }, -- the server components
	context_id: number
)
	local ent = get_entity(id, "client", context_id)
	local true_cts = {}

	print("added server id", id)

	for name, ctype in components do
		local true_ctype = cts[name]
		true_cts[ctype] = true_ctype
	end

	registry:set(ent, cts.ServerComponents, true_cts)
	servers["client"][id] = ent

	print("created values", true_cts)
end

return add_local_server
