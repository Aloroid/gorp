local vide = require(script.Parent.Parent.Parent.vide)

local source = vide.source
local derive = vide.derive

local ids = source({} :: { [any]: string })
local keys = derive(function()
	local t = {}

	for key, value in ids() do
		t[value] = key
	end

	return t
end)

return {
	ids = ids,
	keys = keys,
}
