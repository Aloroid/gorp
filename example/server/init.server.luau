local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cts = require(ReplicatedStorage.Shared.cts)
local gorp = require(ReplicatedStorage.Packages.gorp)
local world = require(ReplicatedStorage.Shared.registry)

for i = 1, 100 do
	local id = world:create()
	world:add(id, cts.Name, cts.Transform)
end

gorp.add_world(world)

for i = 1, 1000 do
	local thing = world:create()
	world:add(thing, cts.Name, cts.Transform)

	task.spawn(function()
		while task.wait(1) do
			if world:has(thing, cts.Name) then
				world:remove(thing, cts.Name)
			else
				world:add(thing, cts.Name)
			end
		end
	end)
end
