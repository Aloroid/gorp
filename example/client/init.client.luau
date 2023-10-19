local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local cts = require(ReplicatedStorage.Shared.cts)
local gorp = require(ReplicatedStorage.Packages.gorp)
local world = require(ReplicatedStorage.Shared.registry)

for i = 1, 100 do
	local id = world:create()
	world:add(id, cts.Name, cts.Transform)
end

print("hi")
gorp.add_world(world)
print("boop")
gorp.spawn_widget("registry_selector")
print("?")

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F2 then
		gorp.enabled(not gorp.enabled())
	end
end)

for i = 1, 100 do
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

print("added scheduler")
local scheduler = gorp.scheduler.new()

RunService.Heartbeat:Connect(function()
	for i = 1, 25 do
		scheduler:before(`system {i}`)
		for id, transform in world:view(cts.Transform) do
			world:set(id, cts.Transform, transform * CFrame.new(0, 1, 0))
		end
		scheduler:after()
	end
	scheduler:finish()
end)
