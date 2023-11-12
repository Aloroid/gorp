local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local cts = require(ReplicatedStorage.Shared.cts)
local ecr = require(ReplicatedStorage.Packages.ecr)
local gorp = require(ReplicatedStorage.Packages.gorp)
local world = require(ReplicatedStorage.Shared.registry)

local new = ecr.component(function() return true end)

gorp.compat_set_cts({ test = new })

for i = 1, 5 do
	local id = world:create()
	world:add(id, cts.Name, cts.Transform, new)
end

for i = 1, 5 do
	local id = world:create()
	world:add(id, cts.Name, cts.Transform, new)
	world:set(id, cts.Name, "parallel")
end

gorp.add_world(world, "parallel!")

for i = 1, 5 do
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

local scheduler = gorp.scheduler.new()

RunService.Heartbeat:Connect(function()
	scheduler:before("double query (different actor tho)")
	for id, transform in world:view(cts.Transform, cts.Name) do
		world:set(id, cts.Transform, transform * CFrame.new(0, 1, 0))
	end
	scheduler:after()

	scheduler:before("single")
	for id, transform in world:view(cts.Transform) do
		world:set(id, cts.Transform, transform * CFrame.new(0, 1, 0))
	end
	scheduler:after()
	scheduler:finish()
end)
