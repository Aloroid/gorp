local HTTPService = game:GetService("HttpService")

local rbxjson = {}

rbxjson.deconstruct = {
	Color3 = function(e: Color3)
		return e:ToHex()
	end,
	CFrame = function(e: CFrame)
		return { e:GetComponents() }
	end,
	Vector3 = function(e: Vector3)
		return { X = e.X, Y = e.Y, Z = e.Z }
	end,
	Vector2 = function(e: Vector2)
		return { X = e.X, Y = e.Y }
	end,
	UDim2 = function(e: UDim2)
		return {
			Scale = { X = e.X.Scale, Y = e.Y.Scale },
			Offset = { X = e.X.Scale, Y = e.Y.Scale },
		}
	end,
	UDim = function(e: UDim)
		return { Scale = e.Scale, Offset = e.Offset }
	end,
}

rbxjson.construct = {
	Color3 = function(e: string)
		return Color3.fromHex(e)
	end,

	CFrame = function(e)
		return CFrame.new(unpack(e))
	end,
	Vector3 = function(e)
		return Vector3.new(e.X, e.Y, e.Z)
	end,
	Vector2 = function(e)
		return Vector3.new(e.X, e.Y)
	end,

	UDim2 = function(e)
		return UDim2.new(e.Scale.X, e.Offset.X, e.Scale.Y, e.Offset.Y)
	end,
	UDim = function(e)
		return UDim.new(e.Scale, e.Offset)
	end,
}

rbxjson.construct_array = {
	Color3 = function(...)
		return Color3.fromRGB(...)
	end,

	CFrame = function(...)
		return CFrame.new(...)
	end,
	Vector3 = function(...)
		return Vector3.new(...)
	end,
	Vector2 = function(...)
		return Vector3.new(...)
	end,

	UDim2 = function(...)
		return UDim2.new(...)
	end,
	UDim = function(...)
		return UDim.new(...)
	end,
}

local function search_encode(to_encode)
	local t = {}
	for k, v in to_encode do
		if type(v) == "table" then
			t[k] = search_encode(v)
		else
			local needle = rbxjson.deconstruct[typeof(v)]
			if needle then
				t["§" .. typeof(v) .. "§" .. k] = needle(v)
			else
				t[k] = v
			end
		end
	end
	return t
end

local function search_decode(to_decode)
	local t = {}
	for k, v in to_decode do
		if typeof(v) == "table" then
			t[k] = search_decode(v)
			for c, f in rbxjson.construct :: any do
				local query = "§" .. c .. "§"
				local found = string.find(k, query)
				if found then
					t[string.sub(k, #query + 1, #k)] = f(v)
					t[k] = nil
				end
			end
		else
			t[k] = v
		end
	end
	return t
end

function rbxjson.prettify(json_str)
	local indent = 0
	local result = ""
	local in_string = false

	for i = 1, #json_str do
		local char = json_str:sub(i, i)

		if char == '"' and (i == 1 or json_str:sub(i - 1, i - 1) ~= "\\") then in_string = not in_string end

		if not in_string then
			if char == "{" or char == "[" then
				indent = indent + 1
				result = result .. char .. "\n" .. string.rep("\t", indent)
			elseif char == "}" or char == "]" then
				indent = indent - 1
				result = result .. "\n" .. string.rep("\t", indent) .. char
			elseif char == "," then
				result = result .. char .. "\n" .. string.rep("\t", indent)
			else
				result = result .. char
			end
		else
			result = result .. char
		end
	end

	return result
end

function rbxjson.encode(arg: unknown)
	if typeof(arg) == "table" then
		local deconstructed = search_encode(arg)
		return HTTPService:JSONEncode(deconstructed)
	else
		return HTTPService:JSONEncode(arg)
	end
end

function rbxjson.decode(json, type)
	local success, result = pcall(function()
		return HTTPService:JSONDecode(json)
	end)
	if success and typeof(result) == "table" then
		return search_decode(result)
	elseif type then
		if not rbxjson.construct_array[type] then
			return HTTPService:JSONDecode(json)
		else
			local output_array = {}
			for c in string.gmatch(json, "%s*([^,%s]+)%s*") do
				table.insert(output_array, c)
			end
			return rbxjson.construct_array[type](unpack(output_array))
		end
	end

	return
end

return rbxjson
