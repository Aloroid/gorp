local remotes = require(script.Parent.Parent.remotes)
local scheduler = require(script.Parent.Parent.scheduler)
local scheduler_view = require(script.Parent.scheduler_view)

return function(name, index)
	local scheduler = scheduler.new(`{name} (server)`, true, 1)

	local function update_scheduler(update_index, data)
		if update_index ~= index then return end -- for someone else

		for index, value in data do
			local name, time, paused = string.unpack("zfB", value)
			paused = paused > 0

			if paused then
				scheduler:pause(index)
				scheduler:skip(name)
			else
				scheduler:resume(index)
				scheduler:_before(name)
				scheduler:_after(time)
			end
		end
		scheduler:finish()
	end

	update_scheduler(
		index,
		remotes.subscribe_scheduler_data:InvokeServer(index)
	)
	local connection =
		remotes.update_scheduler_data.OnClientEvent:Connect(update_scheduler)

	local clone = table.clone(scheduler) :: any

	function clone:pause(system)
		remotes.pause_scheduler_system:FireServer(index, system)
	end

	function clone:resume(system)
		remotes.resume_scheduler_system:FireServer(index, system)
	end

	return scheduler_view(clone :: any, function()
		connection:Disconnect()
		remotes.unsubscribe_scheduler_data:InvokeServer(index)
	end, index)
end
