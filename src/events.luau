--[[

	contains a bunch of Events that you can listen to.

]]

local net = require(script.Parent.modules.net)

return {

	test = net.create_callback("test", true),
}
