local actions = require(script.Parent.Parent.actions)
local rts = require(script.Parent.Parent.rts)
local vide = require(script.Parent.Parent.Parent.vide)

local performance = require(script.performance)
local system_query_hook = require(script.Parent.Parent.system_query_hook)
local system_watch_hook = require(script.Parent.Parent.system_watch_hook)
local tabs = require(script.Parent.Parent.components.tabs)
local watch = require(script.watch)
local widget = require(script.Parent.Parent.components.widget)

local source = vide.source
local derive = vide.derive

return function(scheduler: rts.Scheduler, index: number)
	local system = scheduler.systems[index]

	-- system watch
	local hook = system_watch_hook.new(scheduler, index)
	local frame = source(0)
	local disable: (() -> ())?

	local recording = source(false)
	vide.effect(function()
		if disable then
			disable()
			disable = nil
		end

		if recording() then disable = hook:enable() end
	end)

	return widget {

		title = system.name,
		min_size = Vector2.new(230, 200),
		closeable = true,

		actions.cleanup(function()
			if disable then disable() end
		end),

		tabs {
			{
				name = "Performance",
				child = function()
					local hook = system_query_hook.new(scheduler, index)

					return performance(
						system.time,
						hook.views :: any,
						hook:enable()
					)
				end,
			},
			{
				name = "Watch",
				child = function()
					return watch(
						hook.total_changes,
						frame,
						derive(function()
							if recording() == false then
								return hook.frames()[frame()] or {}
							else
								return {}
							end
						end),
						recording,
						function() end
					)
				end,
			},
		},
	}
end
