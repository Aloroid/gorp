local actions = require(script.Parent.Parent.actions)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local corner = require(script.Parent.corner)

local create = vide.create
local source = vide.source

type Text = {

	layout: { [any]: any }?,

	text: string | () -> string,
	text_size: number?,
	font: Enum.Font?,
	color: Color3? | (() -> Color3)?,
}

local function text(props: Text)
	local hovering = source(false)
	local pressed = source(false)

	return create "TextLabel" {

		AutomaticSize = Enum.AutomaticSize.XY,

		BackgroundTransparency = 1,

		Text = props.text,
		TextColor3 = props.color or style.text,
		TextSize = props.text_size or style.font_size,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = props.font or style.font,

		actions.hovering(hovering),
		actions.pressed(pressed),

		corner {},
		props.layout,
	}
end

return text
