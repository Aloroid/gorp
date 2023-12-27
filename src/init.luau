--[[

	gorp 0.2 is a undertaking to improve gorp's capabilities and backend

]]

local RunService = game:GetService("RunService")

local server = require(script.server)
local stop_multi_require = require(script.modules.stop_multi_require)

return {

	hook_world = server.hook_world,
	scheduler = server.scheduler,
	names = server.names,

	get_client = function()
		assert(
			RunService:IsClient(),
			"gorp client cannot be received on the server"
		)
		stop_multi_require("cannot get client twice")
		return require(script.client)
	end,
}
