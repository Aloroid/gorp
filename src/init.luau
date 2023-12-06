--[[

	gorp 0.2 is a undertaking to improve gorp's capabilities and backend

]]

local events = require(script.events)
--local server = require(script.server)

events.test:set_callback(
	function(connector, name: string) return `Hello, {name}!` end
)

return {

	--add_world = server.add_world,
	--scheduler = server.scheduler,
	--names = server.names,

	test_callback = events.test,
}
