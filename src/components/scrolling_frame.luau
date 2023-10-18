local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)

local create = vide.create

type props = { [any]: any }

local function scrolling_frame(props: props)
	return create "ScrollingFrame" {

		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.fromScale(0, 0),

		BackgroundColor3 = style.background,

		ScrollBarImageColor3 = style.scroll_bar,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		ScrollBarThickness = 6,

		props,
	}
end

return scrolling_frame
