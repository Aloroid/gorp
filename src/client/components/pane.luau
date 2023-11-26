--[[

	Provides a background with padding

]]

local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local background = require(script.Parent.background)
local border = require(script.Parent.border)
local container = require(script.Parent.container)
local corner = require(script.Parent.corner)
local text = require(script.Parent.text)

local create = vide.create

type props = {
	title: (string | () -> string)?,

	[any]: any,
}

local function pane(props: props)
	local title = props.title

	props.title = nil

	return background {

		Size = UDim2.new(1, 0, 0, 32),
		AutomaticSize = Enum.AutomaticSize.Y,

		border {},
		corner {},

		container {
			Name = "Name",

			Position = UDim2.fromScale(0, 0),
			AnchorPoint = Vector2.new(0, 1),
			Size = UDim2.new(),
			AutomaticSize = Enum.AutomaticSize.XY,

			BackgroundColor3 = style.background,
			BackgroundTransparency = 0,

			create "UIPadding" {
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 2),
				PaddingTop = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 2),
			},

			create "UIListLayout" {
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},

			Visible = function() return not not title end,

			text {
				text = title or "",
				text_size = 14,

				layout = { TextColor3 = style.sub_text },
			},
		},

		container {

			Name = "Container",

			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,

			create "UIPadding" {
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 2),
				PaddingTop = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 2),
			},

			props,
		},

		Visible = props.Visible,
	}
end

return pane
