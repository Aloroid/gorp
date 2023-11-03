--[[

	Retrieves a identifier

]]

local efficient_pack_int = require(script.Parent.efficient_pack_int)
local get_identifier_namespace = require(script.Parent.get_identifier_namespace)

local function identifier_get(namespace_key: string, key: string)
	local id = efficient_pack_int.unpack(key, true)
	return get_identifier_namespace(namespace_key).values[id]
end

return identifier_get
