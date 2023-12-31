local button = require(script.Parent.Parent.components.button)
local vide = require(script.Parent.Parent.Parent.Parent.vide)
local widget = require(script.Parent.Parent.components.widget)

local create = vide.create

return function(target: ScreenGui)
	return vide.mount(function()
		return create "Folder" {

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
			},

			widget {

				widget_id = "test",
				title = "hi 1",
				min_size = Vector2.new(100, 100),

				closeable = true,

				button {
					text = "testing this",
				},
			},
		}
	end, target)
end
