local vide = require(script.Parent.Parent.Parent.vide)

local source = vide.source
local derive = vide.derive

local map = source({} :: { [number]: number })
local reverse_map = derive(function()
	local t = {}

	for key, value in map() do
		t[value] = key
	end

	return t
end)
local ids = source({} :: { [any]: string })
local keys = derive(function()
	local t = {}

	for key, value in ids() do
		t[value] = key
	end

	return t
end)

return {
	map = map,
	reverse = reverse_map,
	ids = ids,
	keys = keys,
}
