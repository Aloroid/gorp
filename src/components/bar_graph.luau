--[[

	A bar graph component, useful for displaying how much something 

]]

local vide = require(script.Parent.Parent.Parent.vide)

type props = {

	max: vide.Source<number>,
	data: vide.Source<{ number }>,
}
