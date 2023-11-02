local vide = require(script.Parent.Parent.Parent.Parent.vide)

local button = require(script.Parent.Parent.components.button)
local dock = require(script.Parent.Parent.components.dock)
local create = vide.create

return function(target: ScreenGui)
	return vide.mount(
		function()
			return create "Folder" {

				create "UIListLayout" {
					FillDirection = Enum.FillDirection.Horizontal,
				},

				dock {

					widget_id = "test",
					title = "hi 1",
					min_size = 100,

					closeable = false,

					button {
						text = "testing this",
					},
				},

				dock {

					widget_id = "test",
					title = "hi 2",
					min_size = 100,

					button {
						text = "testing this",
					},
				},

				dock {

					widget_id = "test",
					title = "testing more",
					min_size = 100,

					button {
						text = "testing this",
					},
				},
			}
		end,
		target
	)
end
