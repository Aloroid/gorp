--[[

	A generic layer for ECS to make implementing support for other ECS modules
	for Gorp easier.

	By default we do not include support for any library and this has to be
	manually implemented by the user.

]]

local convert_scale = require(script.Parent.modules.convert_scale)
local ecr = require(script.Parent.Parent.ecr)

type World = any
type Component = any
type Entity = any

return {

	--- This function is called in order to display to the user what id some entity is associated with.
	--- Feel free to format this in any way
	id = function(id)
		local key, ver = ecr.inspect(id)
		return `{key}:{ver}`
	end,

	--- This function will be used to get a value from a component
	get = function(world, id, ctype)
		return world:try_get(id, ctype)
	end,

	--- This function will be used to iterate over a given query.
	query = function(world, included, excluded)
		local iterator = world:view(unpack(included)):exclude(unpack(excluded))
		return iterator :: any
	end,

	--- This function will be used to write a value to an entity of the world
	write = function(world, id, ctype, value)
		world:set(id, ctype, value)
	end,

	--- This function should be called to listen for whenever a ctype change happens, and then run the callback.
	--- It will then return a function that can be used to disconnect the callback.
	--- This has to be implemented in order to allow the registry to update live.
	on_change = function(world, ctype, callback)
		local connection = world:on_change(ctype):connect(callback)
		return function()
			connection:disconnect()
		end
	end,

	--- system_labels are a collection of functions used to add extra categories and labels to systems.
	--- These extra labels will then be displayed under the Performance widget of each system.
	system_labels = {
		{
			category = "General Performance",

			capture = function(resume)
				local start = os.clock()
				resume()
				local finish = os.clock()
				local b = buffer.create(4)
				buffer.writef32(b, 0, finish - start)
				return b
			end,

			decode = function(packet)
				local s = buffer.readf32(packet, 0)
				return {`Last Frame\n{convert_scale(s, "s")}`}
			end
		},
		{
			category = "View Performance",

			capture = function(resume)
				--FIXME: cyclic require
				local query_hook = require(script.Parent.query_hook) 
				return query_hook.capture(resume)
			end,

			decode = function(packet, names)
				local query_hook = require(script.Parent.query_hook)
				return query_hook.decode(packet, names)
			end,
		}
	},
} :: {

	--- This function will be used when displaying the registry.
	id: (id: Entity) -> string,
	--- This function will be used to get a value from a component
	get: (world: World, id: Entity, component: Component) -> unknown?,
	--- This function will be used to iterate over a given query.
	query: (world: World, included: { Component }, excluded: { Component }) -> () -> Entity,
	--- This function will be used to write a value to the world
	write: (world: World, id: Entity, component: Component, value: unknown) -> (),
	--- This function should be called to listen for whenever a ctype change happens, and then run the callback.
	--- It will then return a function that can be used to disconnect the callback
	on_change: (world: World, component: Component, callback: (id: Entity) -> ()) -> () -> (),

	system_labels: {
		{
			category: string,

			capture: (resume: () -> ()) -> any,
			decode: (any, {[number]: string}) -> { string },
		}
	},
}
