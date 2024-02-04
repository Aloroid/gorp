--[[

	gorp 0.2 is a undertaking to improve gorp's capabilities and backend

]]

local RunService = game:GetService("RunService")

local convert_scale = require(script.modules.convert_scale)
local generic_ecs_layer = require(script.generic_ecs_layer)
local server = require(script.server)
local traffic_check = require(script.modules.traffic_check)

return {

	hook_world = server.hook_world,
	scheduler = server.scheduler,
	names = server.names,
	get_worlds = server.get_worlds,
	components = server.components,

	overwrite_check_function = traffic_check.overwrite_check_function,

	ecs_layer = generic_ecs_layer,
	convert_scale = convert_scale,

	get_client = function()
		assert(RunService:IsClient(), "gorp client cannot be received on the server")
		return require(script.client)
	end,
}
