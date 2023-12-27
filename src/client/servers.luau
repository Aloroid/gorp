type Server = {

	actor_id: number,

	ctypes: { [unknown]: string },
	ctype_names: { [string]: unknown },

	registries: { { name: string, id: number } },
	schedulers: { { name: string, id: number } },
}

return {

	server = {} :: { [number]: Server },
	client = {} :: { [number]: Server },
} :: { [string]: { [number]: Server } }
