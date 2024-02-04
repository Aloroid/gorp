--[[

	Border with clear lines to indicate where it ends.
	Does not apply the border on the text.

]]

local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local create = vide.create

local function corner(props: vide.vUIStroke)
	return create "UIStroke" {

		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
		Color = style.border,

		props,
	}
end

return corner
