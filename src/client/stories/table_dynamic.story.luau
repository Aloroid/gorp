local background = require(script.Parent.Parent.components.background)
local layout = require(script.Parent.Parent.components.layout)
local table_display = require(script.Parent.Parent.components.table)
local text = require(script.Parent.Parent.components.text)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local source = vide.source

return function(target: ScreenGui)
	return vide.mount(function()
		return background {

			layout {},

			table_display {

				meaning = source({
					"Id",
					"Position",
					"Health",
					"MaxHealth",
					"Rotation",
				}),
				max_rows = source(5000000),

				display = function(value: () -> any, column, row)
					return text {
						layout = { Size = UDim2.new(1, 0, 0, 24) },

						text = function() return `{column}:{row()}` end,
					}
				end,

				item_size = 24,
			},
		}
	end, target)
end
