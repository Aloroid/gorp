local vide = require(script.Parent.Parent.Parent.Parent.vide)

local background = require(script.Parent.Parent.components.background)
local foreground = require(script.Parent.Parent.components.foreground)
local tabs = require(script.Parent.Parent.components.tabs)
local text = require(script.Parent.Parent.components.text)

return function(target: ScreenGui)
	local destroy = vide.mount(function()
		return background {

			tabs({

				{
					name = "Editor",
					child = function()
						return foreground {
							text {
								text = "insert lorem ipsum",
							},
						}
					end,
				},

				{
					name = "Exporter",
					child = function()
						return foreground {
							text {
								text = "insert lorem ipsum 2",
							},
						}
					end,
				},
			}),
		}
	end, target)

	return function() destroy() end
end
