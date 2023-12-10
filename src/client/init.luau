--[[

	the client object should only be created once on the client.

]]

local RunService = game:GetService("RunService")

local add_server = require(script.add_server)
local events = require(script.Parent.events)
local gorp_selector = require(script.widgets.gorp_selector)
local new_scheduler = require(script.Parent.server.scheduler)
local replicate_components = require(script.systems.replicate_components)
local replicate_core = require(script.systems.replicate_core)
local stop_multi_require = require(script.Parent.modules.stop_multi_require)
local vide = require(script.Parent.Parent.vide)

stop_multi_require()

-- create all the connections necessary
events.replicate_core_data:connect(function(connector)
	-- adds the server
	add_server(connector.from :: number, if connector.player then "client" else "server")
end)

local scheduler = new_scheduler("gorpclient")
RunService.Heartbeat:Connect(function()
	scheduler:system("replicate_core", replicate_core)
	scheduler:system("replicate_components", replicate_components)
	scheduler:finish()
end)

print("requested for servers")
events.request_servers:fire({
	namespace = "client",
})

events.request_servers:fire({
	namespace = "server",
})

vide.strict = false

return {

	gorp_selector = gorp_selector,
}
