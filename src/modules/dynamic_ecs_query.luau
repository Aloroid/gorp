--!native
--[[

	dynamic_ecs_query allows for dynamically querying and returns a result.

]]

local ecr = require(script.Parent.Parent.Parent.ecr)
local rts = require(script.Parent.Parent.rts)
local stream = require(script.Parent.stream)

type ParsedECSQuery = {
	ok: false,
	err: string,
} | {
	ok: true,
	included_names: { string },
	included: { number | any },
	included_no_tags: { number | any },
	excluded: { number },
	equal: { number },
	equal_values: { (value: unknown) -> boolean },
}

export type Query = {

	registry: rts.Registry,
	invalidated: boolean,
	query: ParsedECSQuery,
	ids: { number },
}

local functions = {
	Vector3 = Vector3.new,
	CFrame = CFrame.new,
	Vector2 = Vector2.new,
	Color3 = Color3.new,
}
local numbers = {
	"0",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
}

-- removes trailing whitespace
local function reduce(input: string) return string.gsub(string.gsub(input, "^%s*", ""), "%s*$", "") end

local parse_value = function(query: string, cts: { [string]: number })
	debug.profilebegin("parsing query")
	local included = {}
	local excluded = {}
	local equal = {}
	local equal_values = {}
	local include_names = {}
	local include_no_tags = {}

	local already_used = {}
	local already_equals = {}

	local stack = {}
	local func_call: false | { fn: (...any) -> any, tuple: { any } } = false
	local parsed_value
	local stream = stream(query)

	local stored_equal_ctype_name: string?

	local ctype_type: false | "include" | "exclude" | "equal" | "notequals" = false

	local is_number = false
	local is_string: false | "'" | '"' = false

	local ok, err = true, ""

	local function croak(msg: string)
		ok, err = false, msg
	end

	local function parse_num_or_bool()
		if is_number then
			local token = stream:next_token(1)
			parsed_value = tonumber(token) :: any
			if parsed_value == nil then croak(`{token} is not a number`) end
			is_number = false
		elseif not is_string and stream:token(1) == "true" then
			parsed_value = true
			stream:next_token()
		elseif not is_string and stream:token(1) == "false" then
			parsed_value = false
			stream:next_token()
		end
	end

	local function append()
		local name = reduce(stored_equal_ctype_name or stream:next_token(1))
		local ctype = cts[name]

		if ctype_type == "include" then
			if ctype == nil then
				croak(`"{name}" is not a component`)
				return
			end
			if already_used[name] then croak(`"{name}" is already used earlier in the query"`) end
			already_used[name] = true
			ctype_type = false
			if not ecr.is_tag(ctype) then
				table.insert(include_names, name)
				table.insert(include_no_tags, ctype)
			end

			if table.find(included, ctype) then return end
			table.insert(included, ctype)
		elseif ctype_type == "exclude" then
			if ctype == nil then croak(`"{name}" is not a component`) end
			if already_used[name] then croak(`"{name}" is already used earlier in the query"`) end
			already_used[name] = true
			ctype_type = false
			table.insert(excluded, ctype)
		elseif ctype_type == "equal" then
			parse_num_or_bool()
			if ctype == nil then
				croak(`"{name}" is not a component`)
				return
			end
			if already_equals[ctype] then
				croak(`"{name}" is already being compared`)
				return
			end
			table.insert(equal, ctype)
			table.insert(equal_values, function(value: unknown) return parsed_value == value end)

			already_equals[ctype] = true

			ctype_type = false
			stored_equal_ctype_name = nil
			stream:next_token()

			if table.find(included, ctype) then return end
			table.insert(included, ctype)
		elseif ctype_type == "notequals" then
			parse_num_or_bool()
			if ctype == nil then
				croak(`"{name}" is not a component`)
				return
			end
			if already_equals[ctype] then
				croak(`"{name}" is already being compared`)
				return
			end
			table.insert(equal, ctype)
			table.insert(equal_values, function(value: unknown) return parsed_value ~= value end)

			already_equals[ctype] = true

			ctype_type = false
			stored_equal_ctype_name = nil
			stream:next_token()

			if table.find(included, ctype) then return end
			table.insert(included, ctype)
		end
	end

	while not stream:eof() and ok == true do
		stream:next()

		-- we're currently looking for a component
		if not is_string and func_call == false then
			-- include a component
			if stream:peek() == "@" then
				append()
				ctype_type = "include"
				continue
			-- exclude a component
			elseif stream:peek() == "!" then
				append()
				ctype_type = "exclude"
				continue
			elseif stream:peek() == "=" then
				stored_equal_ctype_name = stream:token(1)
				if ctype_type == "include" then append() end

				ctype_type = if ctype_type == "exclude" then "notequals" else "equal"
				func_call = false
				stream:next_token()
				continue
			elseif stream:peek() == " " then
				append()
				ctype_type = false
				stream:next_token()
				continue
			end
		end

		-- starting from here, the component must find a matching value
		-- first, we begin with checking if we have to stop with parsing somethinh
		if ctype_type == "equal" or ctype_type == "notequals" then
			-- check if we're ending a string here
			if is_string and is_string == stream:peek() and stream:last() ~= "\\" then
				parsed_value = stream:next_token(1)
				is_string = false
				continue
			elseif is_string then
				continue
			end

			if stream:peek() == "'" or stream:peek() == '"' and not is_string then
				is_string = stream:peek() :: "'" | '"'
				stream:next_token()
			end

			-- check if the next character is a ,
			if stream:peek() == "," then
				if func_call == false then
					croak(`no tuple to add to`)
					break
				end

				parse_num_or_bool()
				stream:next_token()

				table.insert(func_call.tuple, parsed_value)
			end

			if stream:peek() == ")" then
				if func_call == false then
					croak(`not calling a function`)
					break
				end

				parse_num_or_bool()

				stream:next_token()
				table.insert(func_call.tuple, parsed_value)
				local ok, result = pcall(func_call.fn, unpack(func_call.tuple))

				if ok == false then
					croak(result)
				else
					parsed_value = result
				end

				func_call = table.remove(stack) :: false | { fn: (...any) -> any, tuple: { any } }
			end

			if table.find(numbers, stream:peek()) and stream:token(1) == "" then is_number = true end

			if stream:peek() == "(" then
				local name = reduce(stream:next_token(1))
				local fn = functions[name]
				if fn == nil then croak(`{name} is not a function`) end

				table.insert(stack, func_call)
				func_call = { fn = fn, tuple = {} }
			end
		end
	end

	parse_num_or_bool()
	append()

	debug.profileend()

	if not ok then return { ok = false, err = err } end

	return {
		ok = true,
		included = included,
		excluded = excluded,
		equal = equal,
		equal_values = equal_values,
		included_names = include_names,
		included_no_tags = include_no_tags,
	}
end :: (query: string) -> ParsedECSQuery

local function convert(query: ParsedECSQuery, registry: rts.Registry)
	if query.ok == false then error(`parsed query is invalid: {query.err}`) end

	return {
		registry = registry,
		invalidated = true,
		ids = {},
		query = query,
	}
end

-- gets the current entity
local function get_entity_view(query: Query)
	assert(query.query.ok, "parsed query is invalid")

	if not query.invalidated then return query.ids end

	local parsed = query.query
	local included = parsed.included
	local excluded = parsed.excluded

	if #parsed.included == 0 then included = { ecr.entity } end

	local view = query.registry:view(unpack(included)):exclude(unpack(excluded))
	query.invalidated = false
	return view :: any
end

-- resolves the query and views all the ids inside
local function resolve_query(query: Query, ignore_heuristic: boolean?)
	if query.invalidated == false then return query.ids end
	assert(query.query.ok)

	local view = get_entity_view(query)
	local world = query.registry
	local equal, equal_values = query.query.equal, query.query.equal_values
	query.ids = table.create(#view)

	if ignore_heuristic then
		for id in view do
			table.insert(query.ids, id)
		end
	else
		for id in view do
			local fail = false
			for i, ctype in equal do
				if not equal_values[i](world:try_get(id, ctype)) then
					fail = true
					break
				end
			end
			if fail then continue end
			table.insert(query.ids, id)
		end
	end

	return query.ids
end

-- invalidates the current query, making it require a new View object
local function invalidate_query(query: Query)
	query.invalidated = true
	query.ids = {}
end

return {

	parse_ecs_query = parse_value,
	convert_ecs_query = convert,

	resolve_query = resolve_query,

	invalidate_query = invalidate_query,
}
