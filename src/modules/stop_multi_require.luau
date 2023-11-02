--[[

	This function prevents a module from being required multiple times by
	different Luau vms

]]

local SharedTableRegistry = game:GetService("SharedTableRegistry")

local required_modules =
	SharedTableRegistry:GetSharedTable("_gorp_required_modules")

local function stop_multi_require()
	local s = debug.info(2, "s")

	if required_modules[s] then error("module cannot be required twice") end

	SharedTable.update(required_modules, s, function() return true end)

	return true
end

return stop_multi_require
