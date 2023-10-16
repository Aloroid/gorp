--[[

	Allows for connecting to when a instance is Activated


]]

local vide = require(script.Parent.Parent.Parent.vide)

local action = vide.action

return function(property: string, callback: ((value: unknown) -> ())?)
	return action(function(object: Instance)
		if callback == nil then return end

		callback((object :: any)[property])

		object:GetPropertyChangedSignal(property):Connect(function() callback((object :: any)[property]) end)
	end)
end
