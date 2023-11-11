local cts = require(script.Parent.cts)
local registry = require(script.Parent.registry)

registry:context():set(cts.Components, {})

local cts_names = {}

local function names<T>(components: T & { [string]: any }): T
	for name, ctype in components :: { [string]: any } do
		registry:context():get(cts.Components)[ctype] = name
		cts_names[name] = ctype
	end

	local ent = registry:context().entity

	registry:set(ent, cts.Components, registry:get(ent, cts.Components))

	print("assigned components yay")
	return components
end

return {
	names = names,

	cts_names = cts_names,
}
