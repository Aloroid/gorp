--[[

	Contains internal server state to store the registry and scheduler.

]]

local gorp = require(script.Parent.Parent.gorp)

local entity = "_gorp_long_key_no_one_will_likely_use_❤❤"

return {
	registries = {} :: { { name: string, world: unknown } },
	schedulers = {} :: { gorp.Scheduler },

	--- This is used to store an index with an ctype
	ctype_index = {
		[1] = entity,
	} :: { [number]: unknown },
	--- Map ctype to index
	map_ctype_index = {
		[entity] = 1,
	} :: { [unknown]: number },
	--- This is used to store an name with an index
	ctypes = {
		[1] = "entity",
	} :: { [number]: string },
	--- This is used to store an name with an index
	ctype_index_names = {
		entity = 1,
	} :: { [string]: number },
	--- This is used to associate a name with an ctype
	ctype_names = {
		entity = entity,
	} :: { [string]: unknown },
}
