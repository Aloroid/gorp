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

	A = ecr.component(),
	B = ecr.component(),
	C = ecr.component(),
	D = ecr.component(),
}))
