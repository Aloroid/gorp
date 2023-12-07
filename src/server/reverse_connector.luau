--[[
	utility function to reverse the connector

]]
local rts = require(script.Parent.Parent.rts)

local function reverse(connector: rts.connector): rts.connector
	return {
		namespace = if connector.player then "client" else "server",
		to = connector.from,
		player = connector.player,
	}
end

return reverse
