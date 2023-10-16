local actions = require(script.Parent.Parent.actions)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)

local corner = require(script.Parent.corner)

local create = vide.create
local source = vide.source

type Text = {

	layout: { [any]: any }?,

	text: string | () -> string,
	text_size: number?,
	font: Enum.Font?,
}

local function text(props: Text)
	local hovering = source(false)
	local pressed = source(false)

	return create "TextLabel" {

		AutomaticSize = Enum.AutomaticSize.XY,

		BackgroundTransparency = 1,

		Text = props.text,
		TextColor3 = style.text,
		TextSize = props.text_size or style.font_size,
		Font = props.font or style.font,

		actions.hovering(hovering),
		actions.pressed(pressed),

		corner {},
		props.layout,
	}
end

return text
