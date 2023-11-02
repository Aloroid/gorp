local background = require(script.Parent.Parent.components.background)
local button = require(script.Parent.Parent.components.button)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

return function(target: ScreenGui)
	local destroy = vide.root(function(destroy)
		background {
			Parent = target,

			button {
				text = "Hello World!",
			},
		}

		vide.effect(function() print("test") end)

		return destroy
	end)

	return function() destroy() end
end
