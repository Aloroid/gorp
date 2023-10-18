local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)

local create = vide.create

local function padding(props)
	return create "UIPadding" {

		PaddingTop = style.padding,
		PaddingLeft = style.padding,
		PaddingRight = style.padding,
		PaddingBottom = style.padding,

		props,
	}
end

return padding
