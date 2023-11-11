--[[

	servers can be created across parallel instances and must provide a strong
	interface purely only through signals and functions for the client.

]]

local RunService = game:GetService("RunService")

local common_actor_id = require(script.Parent.common_actor_id)
local components = require(script.components)
local cts = require(script.cts)
local events = require(script.Parent.events)
local registry = require(script.registry)
local replicate_components = require(script.systems.replicate_components)
local replicate_core = require(script.systems.replicate_core)
local rts = require(script.Parent.rts)
local scheduler = require(script.scheduler)

local function add_world(world: rts.Registry, name: string?)
	local ent = registry:create()
	local default_name =
		`Registry {common_actor_id}:{#registry:view(cts.Registry) + 1}`

	registry:set(ent, cts.Name, name or default_name)
	registry:set(ent, cts.Registry, world)
end

local server = {
	add_world = add_world,
	names = components.names,
	scheduler = scheduler,
}

local server_scheduler = scheduler(`gorpserver:{common_actor_id}`)

RunService.Heartbeat:Connect(function()
	server_scheduler:system("replicate_core", replicate_core)
	server_scheduler:system("replicate_components", replicate_components)
	server_scheduler:finish()
end)

local function new_server()
	events.new_server:Fire(common_actor_id, cts, registry:context().entity)
end

events.request_servers.Event:Connect(new_server)
new_server()

return server
