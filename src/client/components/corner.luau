--[[

	UI Corner

]]

local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local create = vide.create

local function corner(props)
	return create "UICorner" {

		CornerRadius = style.corner_radius,
	}
end

return corner
