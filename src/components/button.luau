--[[

	A basic button for actions

]]

local actions = require(script.Parent.Parent.actions)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)

local border = require(script.Parent.border)
local container = require(script.Parent.container)
local corner = require(script.Parent.corner)

local create = vide.create
local source = vide.source

type Button = {

	text: string | () -> string,
	alignment: (Enum.TextXAlignment | () -> Enum.TextXAlignment)?,

	layout: {
		[any]: any,
	}?,
	child: {
		[any]: any,
	}?,

	activated: (() -> ())?,
}

local function button(props: Button)
	local hovering = source(false)
	local pressed = source(false)

	local background = style.button

	return create "TextButton" {

		Size = UDim2.new(1, 0, 0, 24),
		AutomaticSize = Enum.AutomaticSize.Y,

		BackgroundColor3 = function()
			if pressed() then
				return style.button_pressed
			elseif hovering() then
				return style.button_hovering
			else
				return background
			end
		end,
		AutoButtonColor = false,

		Activated = props.activated,

		actions.hovering(hovering),
		actions.pressed(pressed),

		corner {},
		border {},

		container {

			create "TextLabel" {

				AutomaticSize = Enum.AutomaticSize.XY,
				Position = UDim2.fromScale(0, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),

				BackgroundTransparency = 1,

				Text = props.text,
				TextColor3 = style.text,
				TextSize = 16,
				Font = style.font,
			},

			props.child,
		},

		create "UIPadding" {

			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		},

		props.layout,
	}
end

return button
