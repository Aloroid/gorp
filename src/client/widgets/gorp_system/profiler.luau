local border = require(script.Parent.Parent.Parent.components.border)
local container = require(script.Parent.Parent.Parent.components.container)
local style = require(script.Parent.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)

local create = vide.create
local indexes = vide.indexes

type props = {
	max: () -> number,
	values: () -> { number },
	on_hover: ((hovering_index: number) -> ())?,
}

return function(props: props)
	return container {

		Size = UDim2.new(1, 0, 0, 48),
		ClipsDescendants = true,

		indexes(props.values, function(value, key)
			return container {
				Size = function()
					return UDim2.fromScale(1 / 50, value() / props.max())
				end,
				Position = UDim2.fromScale(1 - (key - 1) / 50, 1),
				AnchorPoint = Vector2.new(1, 1),

				BackgroundColor3 = function()
					return if value() / props.max() > 1 then
						Color3.new(1, 0, 0)
					else
						Color3.new(1, 1, 1)
				end,

				BackgroundTransparency = 0,

				MouseEnter = function()
					if not props.on_hover then return end
					props.on_hover(key)
				end,

				MouseLeave = function()
					if not props.on_hover then return end
					props.on_hover(-1)
				end,

				create "UIGradient" {
					Color = ColorSequence.new(style.microprofiler_bar_top, style.microprofiler_bar_bot),
					Rotation = 90,
				},
			}
		end),


		border {},
	}
end
