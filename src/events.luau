--[[

	contains a bunch of Events that you can listen to.

]]

local quick_bindable = require(script.Parent.modules.quick_bindable)

local client_event = quick_bindable.get_client_bindable_event
local server_event = quick_bindable.get_server_bindable_event
local server_func = quick_bindable.get_server_bindable_function

type ClientEvent<T...> = quick_bindable.ClientEvent<T...>
type ServerEvent<T...> = quick_bindable.ServerEvent<T...>
type ServerFunc<T..., U...> = quick_bindable.Function<T..., U...>

type Array<T = unknown> = { T }

return {

	replicate_core_data = client_event("replicate_core_data") :: ClientEvent<
		number,
		{ { name: string, id: number } }, -- registries
		{ { name: string, id: number } } -- schedulers
	>,
	replicate_components = client_event("replicate_components") :: ClientEvent<number, { [string]: number }>,

	new_server = client_event("new_server") :: ClientEvent<number, { [string]: any }, number>,
	request_servers = client_event("request_servers") :: ClientEvent<true>,
}
