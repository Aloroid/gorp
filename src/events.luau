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

	general_replication = client_event("general_replication") :: ClientEvent<
		number,
		Array<Array<number>>,
		Array<Array>,
		Array<Array<number>>,
		Array<number>
	>,
	get_initial_state = server_func("get_initial_state") :: ServerFunc<
		(),
		(Array<Array<number>>, Array<Array>)
	>,

	new_server = client_event("new_server") :: ClientEvent<number, { [string]: any }, number>,
	request_servers = client_event("request_servers") :: ClientEvent<>,
}
