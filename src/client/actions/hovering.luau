--[[

	Allows for connecting to when a instance is being hovered


]]

local vide = require(script.Parent.Parent.Parent.Parent.vide)

local action = vide.action

return function(callback: ((hovering: boolean) -> ())?)
	return action(function(object: Instance)
		assert(object:IsA("GuiObject"), "instance is not a GuiObject")
		if callback == nil then return end

		object.MouseEnter:Connect(function() callback(true) end)

		object.MouseLeave:Connect(function() callback(false) end)
	end)
end
