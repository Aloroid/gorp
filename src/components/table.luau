local debugger = script.Parent.Parent
local packages = debugger.Parent.Parent

local container = require(script.Parent.container)
local style = require(debugger.style)
local vide = require(script.Parent.Parent.Parent.vide)

local background = require(debugger.components.background)
local border = require(debugger.components.border)
local layout = require(debugger.components.layout)
local resizeable_bar = require(debugger.components.resizeable_bar)
local scroller = require(debugger.components.scroller)
local text = require(debugger.components.text)

local create = vide.create
local source = vide.source
local indexes = vide.indexes
local derive = vide.derive

type Table = {

	meaning: vide.Source<{ string }>,
	rows: vide.Source<{ vide.Source<{ any }> }>?,
	max_rows: vide.Source<number>?,

	item_size: number?,

	layout: { [any]: any }?,

	display: (
		(value: () -> any, column: number, row: () -> number) -> Instance
	)?,
}

return function(props: Table)
	local rows = props.rows
	local meaning = props.meaning
	local max_rows = props.max_rows

	assert(rows or max_rows, "either rows or max_rows must be defined")

	local max_items = max_rows
		or function()
			assert(rows, "rows does not exist")
			local rows = rows()
			if rows[1] == nil then return 1 end
			return math.max(1, #rows)
		end

	local sizes = source({})

	local display = props.display
		or function(value)
			return text {
				text = function() return tostring(value()) end,
			}
		end :: never

	return background {

		props.layout,

		layout {
			Padding = UDim.new(0, 0),
		},

		resizeable_bar({
			meaning = meaning,
			sizes = sizes,
		}),

		scroller {

			child = function(row_index)
				local row = derive(function()
					if rows == nil and max_rows ~= nil then
						return table.create(#meaning(), true)
					end
					assert(rows ~= nil, "rows is nil")

					local value = rows()[row_index()]
					return value and value() or {}
				end)

				return create "Frame" {
					Size = UDim2.fromScale(1, 1),

					BackgroundColor3 = style.border,

					indexes(row, function(value, index)
						return container {

							Size = function()
								print("update")
								return UDim2.fromScale(
									if sizes()[index]
										then sizes()[index]()
										else 0,
									1
								)
							end,

							BackgroundColor3 = style.background,
							BackgroundTransparency = 0,

							display(value, index, row_index),

							border {},
						}
					end),

					create "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal,
					},
				}
			end,

			item_size = props.item_size or 32,
			max_items = max_items,

			layout = {
				Size = UDim2.new(1, 0, 1, -32),

				BackgroundColor3 = style.border,
				BackgroundTransparency = 0,

				border {},
			},
		},
	}
end
