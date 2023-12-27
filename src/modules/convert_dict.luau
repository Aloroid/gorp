local function convert_dict(input: { [unknown]: unknown })
	local keys, values = {}, {}

	for key, value in input do
		table.insert(keys, key)
		table.insert(values, value)
	end

	return { keys, values }
end

local function revert_dict(input: { { unknown } })
	local dict = {}

	for i, key in input[1] do
		dict[key] = input[2][i]
	end

	return dict
end

return {
	serialize = convert_dict,
	deserialize = revert_dict,
}
