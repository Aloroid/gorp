--[[

	dynamic_ecs_query allows for dynamically querying and returns a result.

]]

local ecr = require(script.Parent.Parent.ecr)
local rts = require(script.Parent.rts)
local state = require(script.Parent.state)
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
}

export type Query = {

	registry: rts.Registry,
	invalidated: boolean,
	query: ParsedECSQuery,
	ids: { number },
}

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

	local view = get_entity_view(query)
	query.ids = table.create(#view)
	for id in view do
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

	parse_ecs_query = parse_ecs_query,
	convert_ecs_query = convert,

	resolve_query = resolve_query,

	invalidate_query = invalidate_query,
}
