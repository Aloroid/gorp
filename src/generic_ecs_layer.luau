--[[

	A generic layer for ECS to make implementing support for other ECS modules
	for Gorp easier.

	By default we do not include support for any library and this has to be
	manually implemented by the user.

]]

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

	-- UNUSED, might delete later.
	is_tag = function(world, ctype)
		return ecr.is_tag(ctype)
	end,
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
	--- This function should be called to determine if a component is a tag or not
	is_tag: (world: World, component: Component) -> boolean,
}
