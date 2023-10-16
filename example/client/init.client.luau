local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local cts = require(ReplicatedStorage.Shared.cts)
local gorp = require(ReplicatedStorage.Packages.gorp)
local world = require(ReplicatedStorage.Shared.registry)

for i = 1, 100 do
	local id = world:create()
	world:add(id, cts.Name, cts.Transform)
end

gorp.add_world(world, "client")

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F2 then
		gorp.spawn_widget("entity_client_view", {
			world = world,
		})
	end
end)
