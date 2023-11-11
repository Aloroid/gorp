--[[

	the client object should only be created once on the client.

]]

local add_local_server = require(script.add_local_server)
local events = require(script.Parent.events)
local general_replication = require(script.general_replication)
local stop_multi_require = require(script.Parent.modules.stop_multi_require)

stop_multi_require()

events.request_servers:Fire()

-- create all the connections necessary
events.new_server.Event:Connect(add_local_server)
events.general_replication.Event:Connect(
	function(actor, ent, val, rem, des)
		general_replication(actor, "client", ent, val, rem, des)
	end
)

return {}
