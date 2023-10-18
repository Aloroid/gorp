local vide = require(script.Parent.Parent.Parent.Parent.vide)

local container = require(script.Parent.Parent.Parent.components.container)

local create = vide.create
local indexes = vide.indexes
local derive = vide.derive
local source = vide.source

return function(props: {
	values: () -> { { value: number, color: Color3 } },
	selected: vide.Source<number>,
})
	local values = props.values;

	(props :: any).values = nil

	local total = derive(function()
		local total = 0
		for _, value in values() do
			total += value.value
		end
		return total
	end)

	local selected = props.selected or source(0) :: never
	return container {

		Size = UDim2.new(1, 0, 0, 32),

		indexes(values, function(value, index)
			return create "Frame" {

				Size = function()
					return UDim2.fromScale(value().value / total(), 1)
				end,

				BackgroundColor3 = function() return value().color end,

				MouseEnter = function() selected(index) end,
			}
		end),

		create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
		},
	}
end
