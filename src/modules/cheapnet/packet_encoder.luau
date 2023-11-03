--[[

	the packet encoder encodes packets into a special format that is more efficient to send

]]

local is_16bit = false
local cache_8 = {}
local cache_16 = {}

local function add_packet_to_queue(
	queue: { any },
	type: "ordered" | "unordered",
	id: number,
	packet: any
)
	if id > 255 and is_16bit == false then
		warn("16 bit mode enabled, packets now take more space")
	end
	is_16bit = is_16bit or id > 255

	if type == "unordered" then
		queue[id] = queue[id] or {}
		table.insert(queue[id], packet)
	else
		table.insert(queue, { id = id, packet = packet })
	end
end

-- serializes the ordered packets using either 1 byte or 2 byte identifiers.
local function serialize_ordered(
	ordered_queue: { { id: number, packet: any } },
	is_16bit: boolean
)
	local serialized: { any } = table.create(#ordered_queue + 1, false)
	local ids = table.create(#ordered_queue + 1)
	local cache = if is_16bit then cache_16 else cache_8 :: never

	ids[1] = if is_16bit then "H" else "B"

	for i, packet in ordered_queue do
		local id = packet.id
		local string_id = cache[id]
		if string_id == nil then
			string_id = if is_16bit
				then string.pack("H", id)
				else string.char(id)
			cache[id] = string_id
		end

		ids[i + 1] = string_id
		serialized[i + 1] = packet.packet
	end

	serialized[1] = table.concat(ids)
	return serialized
end

local function serialize_unordered(
	unordered_queue: { [number]: { any } },
	is_16bit: boolean
)
	local serialized: { any } = table.create(#unordered_queue + 1)
	local ids = table.create(#unordered_queue + 1)
	local cache = if is_16bit then cache_16 else cache_8 :: never

	ids[1] = if is_16bit then "H" else "B"

	for id, packets in unordered_queue do
		local string_id = cache[id]
		if string_id == nil then
			string_id = if is_16bit
				then string.pack("H", id)
				else string.char(id)
			cache[id] = string_id
		end

		table.insert(ids, string_id)
		table.insert(serialized, packets)
	end

	table.insert(serialized, 1, table.concat(ids))
	return serialized
end

local function get_packet(ordered_queue: { any }, unordered_queue: { any })
	local packet: { any } = {}
	table.insert(packet, serialize_ordered(ordered_queue, is_16bit))
	table.insert(packet, serialize_unordered(unordered_queue, is_16bit))
	ordered_queue = {}
	unordered_queue = {}
	return packet
end

return {
	get_packet = get_packet,
	add_packet_to_queue = add_packet_to_queue,

	serialize_ordered = serialize_ordered,
	serialize_unordered = serialize_unordered,
}
