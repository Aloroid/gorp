local icts = require(script.Parent.cts)
local registry = require(script.Parent.registry)

registry:context():set(icts.Components, {})

local cts_names = {}

local function names<T>(cts: T & { [string]: any }): T
	for name, ctype in cts :: { [string]: any } do
		registry:context():get(icts.Components)[ctype] = name
		cts_names[name] = ctype
	end

	registry
		:context()
		:set(icts.Components, registry:context():get(icts.Components))

	return cts
end

return {
	names = names,

	cts_names = cts_names,
}
