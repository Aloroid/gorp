--!native
--[[

	the packet encoder encodes packets into a special format.

]]

local cache_8 = {}
local cache_16 = {}

for i = 0, 255 do
	cache_8[string.char(i)] = i
end

-- serializes the ordered packets using either 1 byte or 2 byte identifiers.
local function deserialize_ordered(ordered: { any })
	local deserialized = table.create(#ordered)
	local ids = table.remove(ordered, 1) :: string
	local is_16bit = string.sub(ids, 1, 1) == "H"
	local cache = if is_16bit then cache_16 else cache_8 :: never

	for i, packet in ordered do
		local s_id = string.sub(
			ids,
			if is_16bit then i * 2 else i + 1,
			if is_16bit then i * 2 + 1 else i + 1
		)
		local id = cache[s_id]
			or if is_16bit then string.unpack("H", s_id) else string.byte(s_id);

		(if is_16bit then cache_16 else cache_8 :: never)[s_id] = id

		deserialized[i] = { id = id, packet = packet }
	end

	table.freeze(deserialized)
	return deserialized
end

local function deserialize_unordered(unordered: { any })
	local deserialized: { [number]: { any } } = {}
	local ids = table.remove(unordered, 1) :: string
	local is_16bit = string.sub(ids, 1, 1) == "H"

	local cache = if is_16bit then cache_16 else cache_8 :: never

	for i, packets in unordered do
		local s_id = string.sub(
			ids,
			if is_16bit then i * 2 else i + 1,
			if is_16bit then i * 2 + 1 else i + 1
		)
		local id = cache[s_id]
			or (is_16bit and string.unpack("H", s_id) or string.byte(s_id))
		cache[s_id] = id

		deserialized[id] = packets
	end

	return deserialized
end

local function get_packet(packet: { { any } })
	local ordered = deserialize_ordered(packet[1])
	local unordered = deserialize_unordered(packet[2])

	return ordered, unordered
end

return {
	get_packet = get_packet,
	deserialize_ordered = deserialize_ordered,
	deserialize_unordered = deserialize_unordered,
}
