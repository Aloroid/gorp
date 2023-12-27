--[[

	Contains internal server state to store the registry and scheduler.

]]

local gorp = require(script.Parent.Parent.gorp)

return {
	registries = {} :: { { name: string, world: unknown } },
	schedulers = {} :: { gorp.Scheduler },

	--- This is used to store an index with an ctype
	ctype_index = {} :: { [number]: unknown },
	--- Map ctype to index
	map_ctype_index = {} :: { [unknown]: number },
	--- This is used to store an name with an index
	ctypes = {} :: { [number]: string },
	--- This is used to store an name with an index
	ctype_index_names = {} :: { [string]: number },
	--- This is used to associate a name with an ctype
	ctype_names = {} :: { [string]: unknown },
}
