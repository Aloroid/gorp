--[[

	Allows for cleaning up a object like a signal or table easily

]]

local vide = require(script.Parent.Parent.Parent.vide)

local cleanup = vide.cleanup

return function(object: RBXScriptConnection | Instance | {
	Destroy: ((any) -> ())?,
	destroy: ((any) -> ())?,
	Disconnect: ((any) -> ())?,
	disconnect: ((any) -> ())?,
} | () -> ())
	return vide.action(function()
		cleanup(function()
			if typeof(object) == "Instance" then
				object:Destroy()
			elseif typeof(object) == "RBXScriptConnection" then
				object:Disconnect()
			elseif typeof(object) == "function" then
				object()
			else
				if object.Destroy then
					(object :: any):Destroy()
				elseif object.destroy then
					(object :: any):destroy()
				elseif object.Disconnect then
					(object :: any):Disconnect()
				elseif object.disconnect then
					(object :: any):disconnect()
				end
			end
		end)
	end)
end
