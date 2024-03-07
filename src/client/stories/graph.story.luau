local RunService = game:GetService("RunService")

local background = require(script.Parent.Parent.components.background)
local simple_graph = require(script.Parent.Parent.components.simple_graph)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local source = vide.source
local cleanup = vide.cleanup

local N = 20

return function(target: ScreenGui)
	return vide.mount(function()
		local values = {}

		for i = 1, N do
			values[i] = source(math.random())
		end

		cleanup(RunService.Heartbeat:Connect(function(dt)
			for i = 1, N do
				values[i](values[i]() + (math.random() - 0.5) * dt)
			end
		end))

		return background {

			simple_graph {
				values = values,
			},
		}
	end, target)
end
