--[[

	Container to contain multiple frames etc

]]

local vide = require(script.Parent.Parent.Parent.vide)

local create = vide.create

type Container = { [any]: any }

local function container(props: Container)
	return create "Frame" {

		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		props,
	}
end

return container
