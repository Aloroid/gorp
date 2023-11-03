local identifier_state = require(script.Parent.identifier_state)

local function get_identifier_namespace(namespace_key: string)
	local namespace = identifier_state[namespace_key]

	if namespace then
		return namespace
	else
		local new_namespace =
			{ size = 0, keys = {}, values = {}, yielding = {} }
		identifier_state[namespace_key] = new_namespace
		return new_namespace
	end
end

return get_identifier_namespace
