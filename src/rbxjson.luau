local HTTPService = game:GetService("HttpService")

local rbxjson = {}

rbxjson.Deconstruct = {
	Color3 = function(e) return { e.R, e.G, e.B } end,

	CFrame = function(e: CFrame) return { e:GetComponents() } end,
	Vector3 = function(e) return { X = e.X, Y = e.Y, Z = e.Z } end,
	Vector2 = function(e) return { X = e.X, Y = e.Y } end,

	UDim2 = function(e)
		return {
			Scale = { X = e.X.Scale, Y = e.Y.Scale },
			Offset = { X = e.X.Scale, Y = e.Y.Scale },
		}
	end,
	UDim = function(e) return { Scale = e.Scale, Offset = e.Offset } end,
}

rbxjson.Construct = {
	Color3 = function(e) return Color3.new(e.R, e.G, e.B) end,

	CFrame = function(e) return CFrame.new(unpack(e)) end,
	Vector3 = function(e) return Vector3.new(e.X, e.Y, e.Z) end,
	Vector2 = function(e) return Vector3.new(e.X, e.Y) end,

	UDim2 = function(e)
		return UDim2.new(e.Scale.X, e.Offset.X, e.Scale.Y, e.Offset.Y)
	end,
	UDim = function(e) return UDim.new(e.Scale, e.Offset) end,
}

rbxjson.ConstructArray = {
	Color3 = function(...) return Color3.new(...) end,

	CFrame = function(...) return CFrame.new(...) end,
	Vector3 = function(...) return Vector3.new(...) end,
	Vector2 = function(...) return Vector3.new(...) end,

	UDim2 = function(...) return UDim2.new(...) end,
	UDim = function(...) return UDim.new(...) end,
}

function SearchEncode(to_encode)
	local t = {}
	for k, v in to_encode do
		if type(v) == "table" then
			t[k] = SearchEncode(v)
		else
			local needle = rbxjson.Deconstruct[typeof(v)]
			if needle then
				t["§" .. typeof(v) .. "§" .. k] = needle(v)
			else
				t[k] = v
			end
		end
	end
	return t
end

function SearchDecode(to_decode)
	local t = {}
	for k, v in to_decode do
		if typeof(v) == "table" then
			t[k] = SearchDecode(v)
			for c, f in rbxjson.Construct :: any do
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

function rbxjson:Prettify(json_str)
	local indent = 0
	local result = ""
	local in_string = false

	for i = 1, #json_str do
		local char = json_str:sub(i, i)

		if char == '"' and (i == 1 or json_str:sub(i - 1, i - 1) ~= "\\") then
			in_string = not in_string
		end

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

function rbxjson:Encode(arg: unknown)
	if typeof(arg) == "table" then
		local deconstructed = SearchEncode(arg)
		return HTTPService:JSONEncode(deconstructed)
	else
		return HTTPService:JSONEncode(arg)
	end
end

function rbxjson:Decode(json, type)
	local success, result = pcall(
		function() return HTTPService:JSONDecode(json) end
	)
	if success and typeof(result) == "table" then
		return SearchDecode(result)
	elseif type then
		if not rbxjson.ConstructArray[type] then
			return HTTPService:JSONDecode(json)
		else
			local outputArray = {}
			for c in string.gmatch(json, "%s*([^,%s]+)%s*") do
				table.insert(outputArray, c)
			end
			return rbxjson.ConstructArray[type](unpack(outputArray))
		end
	end

	return
end

type JSON = string | number | boolean | { JSON } | { [string]: JSON }
function rbxjson.add_method<T, U>(
	type: string,
	options: {
		deconstruct: ((value: T) -> U & JSON)?,
		construct: ((value: U) -> T)?,
		construct_array: ((...any) -> T)?,
	}
)
	rbxjson.Construct[type] = options.construct or rbxjson.Construct[type]
	rbxjson.Deconstruct[type] = options.deconstruct or rbxjson.Deconstruct[type]
	rbxjson.ConstructArray[type] = options.construct_array
		or rbxjson.ConstructArray[type]
end

return rbxjson
