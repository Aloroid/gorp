--!native
--[[

	dynamic_ecs_query allows for dynamically querying and returns a result.

]]

local ecr = require(script.Parent.Parent.ecr)
local rts = require(script.Parent.rts)
local state = require(script.Parent.state)
local stream = require(script.Parent.stream)
local vide = require(script.Parent.Parent.vide)

local untrack = vide.untrack

local cts = state.cts

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
	equal_values: { any },
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
local function reduce(input: string) return string.gsub(input, "%s*$", "") end

local parse_value = function(query: string)
	local included = {}
	local excluded = {}
	local equal = {}
	local equal_values = {}
	local include_names = {}
	local include_no_tags = {}
	local already_used = {}

	local stack = {}
	local func_call: false | { fn: (...any) -> any, tuple: { any } } = false
	local parsed_value
	local stream = stream(query)

	local stored_equal_ctype_name: string?

	local ctype_type: false | "include" | "exclude" | "equal" = false

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
		local ctype = untrack(cts.keys)[name]

		if ctype_type == "include" then
			if ctype == nil then
				croak(`"{name}" is not a component`)
				return
			end
			if already_used[name] then
				croak(`"{name}" is already used earlier in the query"`)
			end
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
			if already_used[name] then
				croak(`"{name}" is already used earlier in the query"`)
			end
			already_used[name] = true
			ctype_type = false
			table.insert(excluded, ctype)
		elseif ctype_type == "equal" then
			parse_num_or_bool()
			if ctype == nil then croak(`"{name}" is not a component`) end
			table.insert(equal_values, parsed_value)
			table.insert(equal, ctype)

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
				stored_equal_ctype_name = stream:next_token(1)
				ctype_type = "equal"
				func_call = false
				continue
			end
		end

		-- starting from here, the component must find a matching value
		-- first, we begin with checking if we have to stop with parsing somethinh
		if ctype_type == "equal" then
			-- check if we're ending a string here
			if
				is_string
				and is_string == stream:peek()
				and stream:last() ~= "\\"
			then
				parsed_value = stream:next_token(1)
			elseif is_string then
				continue
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

				func_call =
					table.remove(stack) :: false | { fn: (...any) -> any, tuple: { any } }
			end

			if table.find(numbers, stream:peek()) and stream:token(1) == "" then
				is_number = true
			end

			if stream:peek() == "(" then
				local name = reduce(stream:next_token(1))
				local fn = functions[name]
				if fn == nil then croak(`{name} is not a function`) end

				table.insert(stack, func_call)
				func_call = { fn = fn, tuple = {} }
			end
		end
	end

	if not ok then return { ok = ok, err = err } end

	parse_num_or_bool()
	append()

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

local parse_ecs_query = function(query: string)
	local splitted = string.split(query, " ")

	local already_used = {}
	local included_names = {}
	local included = {}
	local included_no_tags = {}
	local excluded = {}

	for _, component_query in splitted do
		local control_character = string.sub(component_query, 1, 1)
		local component_name = string.sub(component_query, 2)
		local component_id = untrack(cts.keys)[component_name]

		-- Perform some checks and return a error about a query.
		if component_query == "" then continue end
		if component_id == nil then
			return {
				ok = false,
				err = `"{component_name}" is not a valid component`,
			}
		end

		if already_used[component_name] then
			return {
				ok = false,
				err = `{component_name} is already earlier in the query.`,
			}
		end

		already_used[component_name] = true

		if control_character == "@" then
			table.insert(included, component_id)
			if ecr.is_tag(component_id) then continue end
			table.insert(included_no_tags, component_id)
			table.insert(included_names, component_name)
		elseif control_character == "!" then
			table.insert(excluded, component_id)
		else
			return {
				ok = false,
				err = `{control_character} is not a valid query controller.`,
			}
		end
	end

	return {
		ok = true,

		included = included,
		included_no_tags = included_no_tags,
		included_names = included_names,
		excluded = excluded,
		equal = {},
		equal_values = {},
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
local function resolve_query(query: Query)
	if query.invalidated == false then return query.ids end
	assert(query.query.ok)

	local view = get_entity_view(query)
	local world = query.registry
	local equal, equal_values = query.query.equal, query.query.equal_values
	query.ids = table.create(#view)
	for id in view do
		local fail = false
		for i, ctype in equal do
			fail = fail and world:get(id, ctype) == equal_values[i]
			if fail then break end
		end
		if fail then continue end
		table.insert(query.ids, id)
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
