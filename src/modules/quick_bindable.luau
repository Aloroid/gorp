--!nolint FunctionUnused
--[[

	A basic remote event wrapper to handle basic networking tasks.

	We opted to use a basic solution rather than something like BridgeNet as it's much simpler.

]]

local Debris = game:GetService("Debris") -- random location to store stuff in

local common_actor_id = require(script.Parent.Parent.common_actor_id)

export type ServerEvent<T...> = {

	Name: string,

	Event: RBXScriptSignal<T...>,
	Fire: (any, server: number, T...) -> (),
}

export type ClientEvent<T...> = {

	Name: string,

	Event: RBXScriptSignal<T...>,
	Fire: (any, T...) -> (),
}

export type Function<T..., U...> = {
	Name: string,

	SetInvoke: (any, callback: (T...) -> U...) -> (),
	Invoke: (any, server: number, T...) -> U...,
}

local function get_server_bindable_event(name: string): any
	local event = script:FindFirstChild(`{name}:server:gorp`) :: BindableEvent
		or (function()
			local bindable = Instance.new("BindableEvent")
			bindable.Name = `{name}:server:gorp`
			bindable.Parent = Debris

			return bindable
		end)()

	return {

		Name = name,

		Event = {
			Connect = function(_, callback)
				event.Event:Connect(function(server: number, ...)
					if server ~= common_actor_id then return end
					callback(...)
				end)
			end,
		},

		Fire = function(_, ...) event:Fire(...) end,
	}
end

local function get_client_bindable_event(name: string): any
	local event = script:FindFirstChild(`{name}:client:gorp`) :: BindableEvent
		or (function()
			local bindable = Instance.new("BindableEvent")
			bindable.Name = `{name}:client:gorp`
			bindable.Parent = Debris

			return bindable
		end)()

	return event
end

local function get_server_bindable_function(name: string): any
	local invoke = get_server_bindable_event(`{name}:invoke`)
	local result = get_server_bindable_event(`{name}:result`)
	local callback = function() end

	invoke.Event:Connect(
		function(actor_id, id: number, ...)
			result:Fire(actor_id, id, callback(...))
		end
	)

	local id = 0

	local function invoke_func(_, server: number, ...)
		local id = id
		local packed
		id += 1

		result.Event:Connect(function(received_id, ...)
			if received_id ~= id then return end

			packed = { ... }
		end)

		invoke:Fire(server, common_actor_id, id, ...)

		while packed == nil do
			task.wait()
		end

		return unpack(packed)
	end

	local function set_invoke(_, new) callback = new end

	return {
		Name = name,

		Invoke = invoke_func,
		SetInvoke = set_invoke,
	}
end

return {

	get_client_bindable_event = get_client_bindable_event,

	get_server_bindable_event = get_server_bindable_event,
	get_server_bindable_function = get_server_bindable_function,
}
