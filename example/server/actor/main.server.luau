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

gorp.pass_config({
	allow_yielding = true,
})

RunService.Heartbeat:Connect(function()
	scheduler:system("parallel", function()
		task.desynchronize()
		for i = 1, 1000 do
			math.sin(i)
		end
		task.synchronize()
	end)

	scheduler:system("sine", function()
		for i = 1, 1000 do
			math.sin(i)
		end
	end)
	scheduler:finish()
end)
