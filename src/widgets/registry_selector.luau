local state = require(script.Parent.Parent.state)
local vide = require(script.Parent.Parent.Parent.vide)

local entity_client_view = require(script.Parent.entity_client_view)

local button = require(script.Parent.Parent.components.button)
local layout = require(script.Parent.Parent.components.layout)
local padding = require(script.Parent.Parent.components.padding)
local pane = require(script.Parent.Parent.components.pane)
local scrolling_frame = require(script.Parent.Parent.components.scrolling_frame)
local widget = require(script.Parent.Parent.components.widget)

local values = vide.values
local cleanup = vide.cleanup

return function()
	local to_cleanup = {}

	return widget {

		title = "Registry Selector",
		min_size = Vector2.new(150, 100),
		closeable = false,

		scrolling_frame {

			AutomaticCanvasSize = Enum.AutomaticSize.Y,

			padding {
				PaddingRight = UDim.new(0, 32),
			},
			layout {
				Padding = UDim.new(0, 16),
			},

			pane {
				title = "worlds",

				layout {},

				values(state.worlds, function(value, key)
					return button {
						text = value.name,

						layout = {
							LayoutOrder = key,
						},

						activated = function()
							state.current_client_world(value)
							table.insert(
								to_cleanup,
								(vide.mount(entity_client_view))
							)
						end,
					}
				end),
			},

			pane {
				title = "schedulers",

				layout {},
			},

			cleanup(function()
				for _, callback in to_cleanup do
					callback()
				end
			end),
		},
	}
end
