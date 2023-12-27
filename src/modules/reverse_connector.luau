--[[
	utility function to reverse the connector

]]
local gorp = require(script.Parent.Parent.gorp)

local function reverse(connector: gorp.connector): gorp.connector
	return {
		namespace = if connector.player then "client" else "server",
		to = connector.from :: number,
		player = connector.player,
	}
end

return reverse
