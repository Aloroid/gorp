--[[

	Container to contain multiple frames etc

]]

local vide = require(script.Parent.Parent.Parent.Parent.vide)

local create = vide.create
local read = vide.read

type props = {
	gap: number? | () -> number,
	[any]: any,
}

local function gap(props: props)
	local gap = props.gap
	props.gap = nil

	return create "Frame" {

		Size = function() return UDim2.fromOffset(read(gap) or 4, read(gap) or 4) end,

		BackgroundTransparency = 1,

		props,
	}
end

return gap
