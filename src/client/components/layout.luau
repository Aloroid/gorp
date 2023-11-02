local vide = require(script.Parent.Parent.Parent.Parent.vide)

local create = vide.create

local function layout(props)
	return create "UIListLayout" {

		Padding = UDim.new(0, 8),

		props,
	}
end

return layout
