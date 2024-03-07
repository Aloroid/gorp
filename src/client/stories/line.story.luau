local RunService = game:GetService("RunService")

local background = require(script.Parent.Parent.components.background)
local line = require(script.Parent.Parent.components.line)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

return function(target: ScreenGui)
	return vide.mount(function()
		local pa = vide.source(Vector3.zero)
		local pb = vide.source(0)

		vide.cleanup(RunService.Heartbeat:Connect(function(dt)
			pb(pb() + dt)
		end))

		return background {

			line {

				pa = function()
					return UDim2.fromScale(0.1, 0.1)
				end,
				pb = function()
					return UDim2.new(pb() % 1 * 0.8 + 0.1, 0, 0.1, 0)
				end,
			},

			line {

				pa = function()
					return UDim2.fromScale(0.5, 0.6)
				end,
				pb = function()
					return UDim2.new(0.1, math.sin(pb()) * 70, 0.5, math.cos(pb()) * 100)
				end,
			},

			line {

				pa = function()
					return UDim2.fromScale(0.5, 0.6)
				end,
				pb = function()
					return UDim2.new(0.9, math.sin(pb()) * 70, 0.5, math.cos(pb()) * 100)
				end,
			},

			line {

				pa = function()
					return UDim2.fromScale(0.5, 0.2)
				end,
				pb = function()
					return UDim2.new(0.9, math.sin(pb()) * 70, 0.5, math.cos(pb()) * 100)
				end,
			},

			line {

				pa = function()
					return UDim2.fromScale(0.5, 0.2)
				end,
				pb = function()
					return UDim2.new(0.1, math.sin(pb()) * 70, 0.5, math.cos(pb()) * 100)
				end,
			},
		}
	end, target)
end
