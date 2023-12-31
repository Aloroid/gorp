--[[

	the client object should only be created once on the client.

]]

local RunService = game:GetService("RunService")

local gorp_selector = require(script.widgets.gorp_selector)
local new_scheduler = require(script.Parent.server.scheduler)
local remotes = require(script.Parent.remotes)
local stop_multi_require = require(script.Parent.modules.stop_multi_require)
local vide = require(script.Parent.Parent.vide)

local replicate_components = require(script.systems.replicate_components)
local replicate_core = require(script.systems.replicate_core)

stop_multi_require()

local scheduler = new_scheduler("gorpclient")
RunService.Heartbeat:Connect(function()
	scheduler:system("replicate_core", replicate_core)
	scheduler:system("replicate_components", replicate_components)
	scheduler:finish()
end)

--print("requested for servers")
remotes.request_servers:fire({
	namespace = "client",
})

remotes.request_servers:fire({
	namespace = "server",
})

vide.strict = true

return {

	gorp_selector = gorp_selector,
}
