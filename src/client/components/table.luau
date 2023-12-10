local container = require(script.Parent.container)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local border = require(script.Parent.border)
local layout = require(script.Parent.layout)
local resizeable_bar = require(script.Parent.resizeable_bar)
local scroller = require(script.Parent.scroller)
local text = require(script.Parent.text)

local create = vide.create
local source = vide.source
local indexes = vide.indexes
local derive = vide.derive

type Table = {

	meaning: vide.Source<{ string }>,
	rows: vide.Source<{ vide.Source<{ any }> }>?,
	max_rows: vide.Source<number>?,
	base_sizes: { number }?,

	item_size: number?,

	layout: { [any]: any }?,

	display: ((value: () -> any, column: number, row: () -> number) -> Instance)?,
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
	local splits = source({})

	-- update splits
	local base_splits = {}
	if props.base_sizes then
		local n = 0
		for i = 1, #props.base_sizes - 1 do
			n += props.base_sizes[i]
			table.insert(base_splits, n)
		end
	end

	local display = props.display
		or function(value)
			return text {
				text = function() return tostring(value()) end,
			}
		end :: never

	local function get_size(index: number)
		local split_before = splits()[index - 1] or source(0) :: never
		local split_after = splits()[index] or source(1) :: never

		local size = split_after() - split_before()
		return size
	end

	return container {

		props.layout,

		layout {
			Padding = UDim.new(0, 0),
		},

		resizeable_bar({
			meaning = meaning,
			sizes = sizes,

			splits = splits,
			base_splits = if #base_splits > 0 then base_splits else nil,
		}),

		scroller {

			child = function(row_index)
				local row = derive(function()
					if rows == nil and max_rows ~= nil then return table.create(#meaning(), true) end
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
								--print("update size row", get_size(index))
								return UDim2.fromScale(get_size(index), 1)
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
