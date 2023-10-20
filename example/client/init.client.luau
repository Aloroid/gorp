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

for i = 1, 10 do
	local id = world:create()
	world:set(id, cts.Name, "foo")
	world:add(id, cts.Transform)
end

for i = 1, 10 do
	local id = world:create()
	world:add(id, cts.Transform)
end

for i = 1, 10 do
	local id = world:create()
	world:set(id, cts.Transform, CFrame.new(Vector3.zero, Vector3.new(0, 5, 5)))
end

for i = 1, 300 do
	local id = world:create()

	if math.random() > 0.5 then world:set(id, cts.A, true) end

	if math.random() > 0.5 then world:set(id, cts.B, true) end

	if math.random() > 0.5 then world:set(id, cts.C, true) end

	if math.random() > 0.5 then world:set(id, cts.D, true) end
end

for i = 1, 100 do
	local id = world:create()
	world:add(id, cts.Position, cts.Velocity)
end

local group = world:group(cts.A, cts.B, cts.C, cts.D)

print("added scheduler")
local scheduler = gorp.scheduler.new()

RunService.Heartbeat:Connect(function()
	scheduler:before("double query")
	for id, transform in world:view(cts.Transform, cts.Name) do
		world:set(id, cts.Transform, transform * CFrame.new(0, 1, 0))
	end
	scheduler:after()

	scheduler:before("update position")
	for id, position, velocity in world:group(cts.Position, cts.Velocity) do
		world:set(id, cts.Position, position + velocity)
	end
	scheduler:after()

	scheduler:before("query A")
	for id in world:view(cts.A) do
	end
	scheduler:after()

	scheduler:before("query AB")
	for id, transform in world:view(cts.A, cts.B) do
	end
	scheduler:after()

	scheduler:before("view ABCD")
	for id, transform in world:view(cts.A, cts.B, cts.C, cts.D) do
	end
	scheduler:after()

	scheduler:before("group ABCD")
	for id, transform in group do
	end
	scheduler:after()

	scheduler:before("multiple queries")
	for id in world:view(cts.A) do
	end

	for id, transform in world:view(cts.A, cts.B) do
	end

	for id, transform in world:view(cts.A, cts.B, cts.C) do
	end
	scheduler:after()

	scheduler:before("none")
	for id in world:view(cts.r) do
	end
	scheduler:after()

	scheduler:finish()
end)

gorp.register_custom_widget(
	"Guide",
	"client",
	function()
		return gorp.components.widget {
			title = "Guide",
			min_size = Vector2.new(200, 200),
			closeable = true,
		}
	end
)
