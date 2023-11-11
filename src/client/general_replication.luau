local cts = require(script.Parent.cts)
local ecr = require(script.Parent.Parent.Parent.ecr)
local registry = require(script.Parent.registry)
local server_ids = require(script.Parent.server_ids)
local servers = require(script.Parent.servers)

local function general_replication(
	actor: number,
	type: "server" | "client",
	entities: { { number } },
	values: { { unknown } },
	removing: { { number } },
	destroying: { number }
)
	local context = servers[type][actor]
	if context == nil then return end

	local server_cts = registry:get(context, cts.ServerComponents)

	for server_ctype_s, entities in entities do
		local server_ctype = tonumber(server_ctype_s) :: number
		local ctype = server_cts[server_ctype]

		for index, server_id in entities do
			local ent = server_ids[type][actor][server_id]

			if ent == nil then
				ent = registry:create()
				registry:set(ent, cts.ActorId, actor)
				registry:set(ent, cts.ReplicatedFrom, type)
				registry:set(ent, cts.ServerId, server_id)
			end

			if ecr.is_tag(ctype) then
				registry:add(ent, ctype)
				continue
			end

			registry:set(ent, ctype, values[server_ctype_s][index])
		end
	end

	for server_ctype, entity in removing do
		server_ctype = tonumber(server_ctype) :: number
		local ctype = server_cts[server_ctype]

		for index, server_id in entities do
			local ent = server_ids[type][actor][server_id]
			if ent == nil then continue end

			registry:remove(ent, ctype)
		end
	end

	for _, entity in destroying do
		local ent = server_ids[type][actor]
		if ent == nil then continue end

		registry:destroy(ent)
	end
end

return general_replication
