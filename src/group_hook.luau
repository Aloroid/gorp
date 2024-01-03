--!optimize 2
--!native
local convert_scale = require(script.Parent.modules.convert_scale)
local ecr = require(script.Parent.Parent.ecr)
local server = require(script.Parent.server)

type StoredViews = {
	{
		includes: { number },
		excludes: { number },
		_get_stats: () -> { time_to_get_next_entity: number, time_to_perform_query: number, total_entities: number },
	}
}

---- * GENERATED WITH ZAP 0.3.3

local outgoing_buff: buffer = buffer.create(64)
local outgoing_used: number = 0
local outgoing_size: number = 64
local outgoing_apos: number

local incoming_buff: buffer
local incoming_read: number

local function read(len: number)
	local pos = incoming_read
	incoming_read = incoming_read + len

	return pos
end

local function alloc(len: number)
	if outgoing_used + len > outgoing_size then
		while outgoing_used + len > outgoing_size do
			outgoing_size = outgoing_size * 2
		end

		local new_buff = buffer.create(outgoing_size)
		buffer.copy(new_buff, 0, outgoing_buff, 0, outgoing_used)

		outgoing_buff = new_buff
	end

	outgoing_apos = outgoing_used
	outgoing_used = outgoing_used + len

	return outgoing_apos
end

local function write_buffer(value)
	local len = #value.includes
	alloc(2)
	buffer.writeu16(outgoing_buff, outgoing_apos, len)
	for i = 1, len do
		alloc(2)
		buffer.writeu16(outgoing_buff, outgoing_apos, value.includes[i])
	end
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.time_next_ent)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.time_perform_ent)
	alloc(4)
	buffer.writeu32(outgoing_buff, outgoing_apos, value.entities)
end

local function read_buffer()
	local value
	value = {}
	value.includes = {}
	local len = buffer.readu16(incoming_buff, read(2))
	for i = 1, len do
		value.includes[i] = buffer.readu16(incoming_buff, read(2))
	end
	value.time_next_ent = buffer.readf32(incoming_buff, read(4))
	value.time_perform_ent = buffer.readf32(incoming_buff, read(4))
	value.entities = buffer.readu32(incoming_buff, read(4))
	return value
end

----

local function inject_world(world: ecr.Registry, used_views: StoredViews)
	local raw_group = world.group

	local function hooked_group(self: ecr.Registry, ...)
		local group = raw_group(self, ...) :: any
		group.includes = { ... }
		local time_to_get_next_entity = 0
		local time_to_perform_query_begin = os.clock()
		local time_to_perform_query_finish = os.clock()
		local total_entities = 0

		table.insert(used_views, group)

		local view_mt = getmetatable(group)
		local raw_iter = view_mt.__iter

		local function iter(self)
			local iterator = raw_iter(self) :: any
			return function()
				local start = os.clock()
				local a, b, c, d, e, f, g, h, i, j, k = iterator()
				local finish = os.clock()
				time_to_get_next_entity += finish - start
				time_to_perform_query_finish = finish
				total_entities += a and 1 or 0
				return a, b, c, d, e, f, g, h, i, j, k
			end
		end

		local function get_results()
			return {
				time_to_get_next_entity = time_to_get_next_entity,
				time_to_perform_query = time_to_perform_query_finish - time_to_perform_query_begin,
				total_entities = total_entities,
			}
		end

		group.iter = iter
		view_mt.__iter = iter
		group._get_stats = get_results

		return group
	end

	-- overwrite the view function
	world.group = hooked_group :: any

	local function uninject()
		world.group = raw_group
	end

	return uninject
end

local function hook(resume: () -> ())
	local stored_views: StoredViews = {}
	local unhook_callbacks = {}

	for _, world in server.get_worlds() do
		local uninject = inject_world(world :: ecr.Registry, stored_views)

		table.insert(unhook_callbacks, uninject)
	end

	resume()

	for _, callback in unhook_callbacks do
		callback()
	end

	local components = server.get_components()

	for _, view in stored_views do
		local stats = view._get_stats()
		local includes = table.clone(view.includes)

		for i, ctype in includes do
			includes[i] = components.map_ctype_index[ctype]
		end

		write_buffer({
			entities = stats.total_entities,
			time_next_ent = stats.time_to_get_next_entity,
			time_perform_ent = stats.time_to_perform_query,
			includes = includes,
		})
	end

	local buff = buffer.create(outgoing_used)
	buffer.copy(buff, 0, outgoing_buff, 0, outgoing_used)

	outgoing_buff = buffer.create(64)
	outgoing_used = 0
	outgoing_size = 64

	return buff
end

local function scale(n: number)
	return convert_scale(n, "s")
end

local function decode(buff: buffer, components: { [number]: string })
	incoming_buff = buff
	incoming_read = 0
	local len = buffer.len(buff)
	local results = {}

	while incoming_read < len do
		local value = read_buffer()
		local includes = value.includes :: { string | number }

		for i, index in includes do
			includes[i] = components[index :: number]
		end

		local str = table.concat(includes, ", ")
		local str2 =
			`{scale(value.time_perform_ent)}\t{scale(value.time_next_ent / value.entities)}/ent\t{value.entities} ent`

		table.insert(results, `{str}\n{str2}`)
	end
	return results
end

return {

	capture = hook,
	decode = decode,
}
