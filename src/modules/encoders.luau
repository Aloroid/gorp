local primitives = {}
local datatypes = {}

local MAX_NESTING = 3

local function encode(value: any, layers: number?)
	local layers = layers or 0
	local datatype = typeof(value)
	local primitive_encoder = primitives[datatype]

	-- this should prevent recursive errors
	if layers > MAX_NESTING then return "error<TOO_DEEP>" end

	if primitive_encoder then return primitive_encoder(value, layers) end

	local encoder = datatypes[datatype]

	if encoder then return `{datatype}<{encoder(value, layers)}>` end

	return `{datatype}<{tostring(value)}>`
end

local function get_key(key: unknown)
	if type(key) == "string" then
		return primitives.string(key)
	else
		return encode(key)
	end
end

primitives.string = function(input: string)
	return string.format("%q", input)
end

primitives.number = function(input: number)
	return string.format("%.14g", input)
end

primitives.boolean = function(input: boolean)
	return tostring(input)
end

datatypes.Vector3 = function(input: Vector3)
	return `{input}`
end

datatypes.Vector2 = function(input: Vector2)
	return `{input}`
end

datatypes.UDim = function(input: UDim)
	return `{input.Scale}, {input.Offset}`
end

datatypes.UDim2 = function(input: UDim2)
	return `{input.X.Scale}, {input.X.Offset}, {input.Y.Scale}, {input.Y.Offset}`
end

datatypes.Color3 = function(input: Color3)
	return `{input:ToHex()}`
end

datatypes.BrickColor = function(input: BrickColor)
	return `{input.Name}`
end

datatypes.Instance = function(input: Instance)
	return `{input:GetFullName()}`
end

primitives.table = function(input, layers: number?)
	if layers > 5 then return `error<"too deeply nested">` end

	local result = { "{" }
	local is_first = true

	for key, value in input do
		if not is_first then table.insert(result, ", ") end
		is_first = false
		table.insert(result, `{get_key(key)}: `)
		table.insert(result, encode(value, layers))
	end

	table.insert(result, "}")

	return table.concat(result)
end

return {
	encode = encode,
}
