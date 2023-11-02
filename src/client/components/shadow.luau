--[[

	Provides a background with padding

]]

local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local create = vide.create

type props = { [any]: any }

local function shadow(props: props)
	return create "ImageLabel" {

		Name = "Shadow",

		Size = UDim2.new(),

		BackgroundTransparency = 1,

		Image = "rbxasset://textures/StudioSharedUI/dropShadow.png",
		ImageColor3 = style.border,

		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 8, 8, 8),
		SliceScale = 0.5,

		create "UIPadding" {
			PaddingLeft = UDim.new(0, 3),
			PaddingRight = UDim.new(0, 3),
			PaddingTop = UDim.new(0, 3),
			PaddingBottom = UDim.new(0, 3),
		},

		props,
	}
end

return shadow
