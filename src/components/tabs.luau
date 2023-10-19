local actions = require(script.Parent.Parent.actions)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)

local background = require(script.Parent.background)
local border = require(script.Parent.border)
local layout = require(script.Parent.layout)
local text = require(script.Parent.text)

local create = vide.create
local source = vide.source
local indexes = vide.indexes

export type tabs = {
	{
		name: string,
		child: () -> Instance,
	}
}

local function tabs(tabs: tabs)
	local selected = source(1)
	local ref = source()
	local cleanup = function() end

	vide.cleanup(cleanup)

	return create "Frame" {

		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		background {
			Name = "Container",

			Position = UDim2.fromOffset(0, 19),
			Size = UDim2.new(1, 0, 1, -19),

			function()
				cleanup()
				local current = selected()
				cleanup = vide.mount(function()
					local object = tabs[current].child()
					vide.cleanup(object)
					return object
				end, ref())
			end,

			border {},
			layout {},

			vide.action(ref),
		},

		create "Frame" {

			Size = UDim2.new(1, 0, 0, 18),

			BackgroundTransparency = 1,

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
			},

			indexes(source(tabs), function(value, index)
				local hovering = source(false)

				return create "TextButton" {

					BackgroundColor3 = function()
						local selected = selected()
						local hovering = hovering()
						if selected == index then
							return style.tab_selected
						elseif hovering then
							return style.tab_hovering
						else
							return style.tab_background
						end
					end,

					Size = UDim2.fromOffset(0, 18),
					AutomaticSize = Enum.AutomaticSize.X,

					TextSize = 14,

					border {},

					actions.hovering(hovering),

					MouseButton1Down = function() selected(index) end,

					create "UIPadding" {
						PaddingLeft = style.padding,
						PaddingRight = style.padding,
					},

					create "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					},

					text {
						text = value().name,
						text_size = 14,
					},
				}
			end),
		},
	}
end

return tabs
