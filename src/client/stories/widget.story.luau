local button = require(script.Parent.Parent.components.button)
local enabled = require(script.Parent.Parent.enabled)
local vide = require(script.Parent.Parent.Parent.Parent.vide)
local widget = require(script.Parent.Parent.components.widget2.widget)

local create = vide.create

return function(target: ScreenGui)
	enabled(true)
	return vide.mount(function()
		return create "Folder" {

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
			},

			widget {

				title = "hi 1",
				min_size = Vector2.new(100, 100),

				button {
					text = "testing this",
				},
			},
		}
	end, target)
end
