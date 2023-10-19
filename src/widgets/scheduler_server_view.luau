local remotes = require(script.Parent.Parent.remotes)
local scheduler = require(script.Parent.Parent.scheduler)
local scheduler_view = require(script.Parent.scheduler_view)

return function(name, index)
	local scheduler = scheduler.new(`{name} (server)`, true, 1)

	local function update_scheduler(data)
		for _, value in data do
			local name, time = string.unpack("zf", value)
			scheduler:before(name)
			scheduler:after(time)
		end
		scheduler:finish()
	end

	update_scheduler(remotes.subscribe_scheduler_data:InvokeServer(index))
	local connection =
		remotes.update_scheduler_data.OnClientEvent:Connect(update_scheduler)

	return scheduler_view(scheduler, function()
		connection:Disconnect()
		remotes.unsubscribe_scheduler_data:InvokeServer(index)
	end, true)
end
