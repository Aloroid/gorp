--[[

	Provides a styled foreground

]]

local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)

local corner = require(script.Parent.corner)
local padding = require(script.Parent.padding)

local create = vide.create

type Foreground = { [any]: any }

local function foreground(props: Foreground)
	return create "Frame" {

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = style.foreground,

		props,

		padding {},
		corner {},
	}
end

return foreground
