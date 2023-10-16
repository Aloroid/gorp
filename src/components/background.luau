--[[

	Provides a background with padding

]]

local padding = require(script.Parent.padding)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)

local create = vide.create

type Background = { [any]: any }

local function background(props: Background)
	return create "Frame" {

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = style.background,

		props,

		padding {},
	}
end

return background
