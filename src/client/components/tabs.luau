local actions = require(script.Parent.Parent.actions)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local background = require(script.Parent.background)
local border = require(script.Parent.border)
local container = require(script.Parent.container)
local layout = require(script.Parent.layout)
local text = require(script.Parent.text)

local create = vide.create
local source = vide.source
local indexes = vide.indexes

export type tabs = {
	{
		name: string,
		child: (active: () -> boolean) -> Instance,
	}
}

local function tabs(tabs: tabs)
	local selected = source(1)
	local ref = source()

	return create "Frame" {

		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		background {
			Name = "Container",

			Position = UDim2.fromOffset(0, 19),
			Size = UDim2.new(1, 0, 1, -18),

			indexes(source(tabs), function(value, index)
				local function is_active()
					return selected() == index
				end

				local object = value().child(is_active)

				return container {
					Name = function()
						return value().name
					end,

					Visible = is_active,

					object,
				} :: Instance
			end),

			border {},
			layout {},

			vide.action(ref),
		},

		create "Frame" {

			Size = UDim2.new(1, 0, 0, 18),

			BackgroundColor3 = style.tab_background,

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
			},

			indexes(function()
				return vide.read(tabs)
			end, function(value, index)
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
							return style.tab_button_background
						end
					end,

					Size = UDim2.fromOffset(0, 18),
					AutomaticSize = Enum.AutomaticSize.X,

					TextSize = 14,

					border {},

					actions.hovering(hovering),

					MouseButton1Down = function()
						selected(index)
					end,

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
				} :: Instance
			end),
		},
	}
end

return tabs
