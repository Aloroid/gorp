local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cts = require(ReplicatedStorage.Shared.cts)
local world = require(ReplicatedStorage.Shared.registry)

for i = 1, 1 do
	local id = world:create()
	world:add(id, cts.Name, cts.Transform)
end
