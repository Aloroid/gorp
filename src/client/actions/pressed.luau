--[[

	Allows for connecting to when a instance is being hovered


]]

local vide = require(script.Parent.Parent.Parent.Parent.vide)

local action = vide.action

local allowed_user_input_types = {
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.Touch,
}

return function(callback: ((hovering: boolean) -> ())?)
	return action(function(object: Instance)
		assert(object:IsA("GuiObject"), "instance is not a GuiObject")
		if callback == nil then return end

		object.InputBegan:Connect(function(input)
			if
				table.find(allowed_user_input_types, input.UserInputType) == nil
			then
				return
			end
			callback(true)
		end)

		object.InputEnded:Connect(function(input)
			if
				table.find(allowed_user_input_types, input.UserInputType) == nil
			then
				return
			end
			callback(false)
		end)
	end)
end
