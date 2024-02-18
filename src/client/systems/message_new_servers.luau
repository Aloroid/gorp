local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)

local new_server = queue(remotes.new_server)

return function()
	for connector in new_server:iter() do
		local reverse = reverse_connector(connector)

		remotes.request_servers:fire(reverse)
	end
end
