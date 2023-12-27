local datatypes = {}

local function get_key(key: string)
	return if string.match(key, "(^[%w])") == nil then key else string.format("%q", key)
end

local function encode(value: any)
	local datatype = typeof(value)
	local encoder = datatypes[datatype]

	if encoder == nil then return tostring(value) end

	return encoder(value)
end

datatypes.Vector3 = function(input: Vector3)
	return `Vector3<{input}>`
end

datatypes.Vector2 = function(input: Vector2)
	return `Vector2<{input}>`
end

datatypes.UDim = function(input: UDim)
	return `UDim<{input.Scale}, {input.Offset}>`
end

datatypes.UDim2 = function(input: UDim2)
	return `UDim2<{input.X.Scale}, {input.X.Offset}, {input.Y.Scale}, {input.Y.Offset}>`
end

datatypes.Color3 = function(input: Color3)
	return `Color3<#{input:ToHex()}>`
end

datatypes.string = function(input: string)
	return string.format("%q", input)
end

datatypes.table = function(input)
	local result = { "{" }
	local is_first = true

	for key, value in input do
		if not is_first then table.insert(result, ", ") end
		is_first = false
		table.insert(result, `{get_key(key)}: `)
		table.insert(result, encode(value))
	end

	table.insert(result, "}")

	return table.concat(result)
end

return {
	encode = encode,
}
