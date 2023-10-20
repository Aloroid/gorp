local background = require(script.Parent.Parent.components.background)
local button = require(script.Parent.Parent.components.button)
local pane = require(script.Parent.Parent.components.pane)
local vide = require(script.Parent.Parent.Parent.vide)

return function(target: ScreenGui)
	return vide.mount(
		function()
			return background {

				pane {
					title = "hi",

					button {
						text = "Hello World!",
					},
				},
			}
		end,
		target
	)
end
