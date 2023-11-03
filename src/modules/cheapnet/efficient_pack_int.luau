--[[
	
	This function will efficiently pack integers to be as small as possible.
	
]]

local BYTE = 256

local function efficient_pack_int(n: number, unsigned: boolean?)
	n = math.round(n) -- automatically round decimal numbers
	assert(
		unsigned == true and n >= 0 or not unsigned,
		"Cannot pack negative numbers as unsigned"
	)

	if unsigned then
		local bytes = math.max(1, math.ceil(math.log(n + 1, BYTE)))
		return string.pack("I" .. bytes, n)
	else
		local bytes = math.ceil(
			math.log(if n >= 0 then n + 1 else math.abs(n) + 1, BYTE / 2)
		)
		return string.pack("i" .. bytes, n)
	end
end

local function efficient_unpack_int(n: string, unsigned: boolean?)
	local size = #n

	if unsigned then
		return string.unpack("I" .. size, n)
	else
		return string.unpack("i" .. size, n)
	end
end

return {
	pack = efficient_pack_int,
	unpack = efficient_unpack_int,
}
