local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ecr = require(ReplicatedStorage.Packages.ecr)
local gorp = require(ReplicatedStorage.Packages.gorp)

local function primitive<T>(value: T): T
	return ecr.component(function() return value end)
end

return gorp.compat_set_cts(ecr.name({

	Name = primitive("gorp"),
	Transform = ecr.component(CFrame.new),
	Position = ecr.component(Vector3.new),
	Velocity = primitive(Vector3.new(0, 0, 1)),
	Raycast = primitive(Vector3.new(0, 1, 0)),
	Amount = primitive(100),

	instance = primitive(Instance.new("Folder", workspace)),

	Object = ecr.component(
		function()
			return {
				Foo = 123,
				Pos = Vector3.new(1, 0, 0),
				Nested = {
					Color = Color3.new(1, 0, 1),
				},
			}
		end
	),

	r = ecr.component(),

	A = ecr.component(),
	B = ecr.component(),
	C = ecr.component(),
	D = ecr.component(),
}))
