type Server = {

	actor_id: number,

	ctypes: { [number]: string },
	ctype_names: { [string]: number },

	registries: { { name: string, id: number } },
	schedulers: { { name: string, id: number } },
}

return {

	server = {} :: { [number]: Server },
	client = {} :: { [number]: Server },
} :: { [string]: { [number]: Server } }
