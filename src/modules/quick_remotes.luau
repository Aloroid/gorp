--!nolint FunctionUnused
--[[

	A basic remote event wrapper to handle basic networking tasks.

	We opted to use a basic solution rather than something like BridgeNet as it's much simpler.

]]

local RunService = game:GetService("RunService")

local common_actor_id = require(script.Parent.Parent.common_actor_id)
local player_verification = require(script.Parent.player_verification)

type Event<T...> = {

	Name: string,

	OnServerEvent: RBXScriptSignal<(Player, T...)>,
	OnClientEvent: RBXScriptSignal<T...>,

	FireServer: (any, target: "client" | "server", server: number, T...) -> (),
	FireClient: (any, player: Player, T...) -> (),

	FireGorpServer: {
		Fire: (any, player: Player, server: number, T...) -> (),
		Event: RBXScriptSignal<(Player, number, T...)>,
	},
}

type Function<T..., U...> = {
	Name: string,

	OnServerInvoke: (Player: Player, T...) -> U...,

	InvokeServer: (any, server: number, T...) -> U...,

	ReturnDataFromGorpServer: {
		Fire: (any, server: number, id: number, T...) -> (),
		Event: RBXScriptSignal<(number, number, T...)>,
	},

	InvokeGorpServer: {
		Fire: (any, server: number, id: number, U...) -> (),
		Event: RBXScriptSignal<(number, number, U...)>,
	},
}

local function get_remote_event(name: string): any
	if RunService:IsServer() then
		local remote = script:FindFirstChild(name) :: any
			or (function()
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = script

				local fire_actor = Instance.new("BindableEvent")
				fire_actor.Name = "FireGorpServer"
				fire_actor.Parent = remote
				return remote
			end)()

		return {

			Connect = function(_, callback)
				return remote.OnServerEvent:Connect(
					function(player: Player, server: number, ...)
						if not player_verification.can_player_use(player) then
							player_verification.punish_player(player)
							return
						end
						if server ~= common_actor_id then return end

						callback(player, ...)
					end
				)
			end,

			FireClient = function(_, player: Player, ...)
				remote:FireClient(player, ...)
			end,
		}
	else
		local remote = script:WaitForChild(name) :: RemoteEvent

		return {

			FireServer = function(
				_,
				target: "client" | "server",
				server: number,
				...
			)
			end,
		}
	end
end

local function get_remote_function(name: string): any
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteFunction
			or (function()
				local remote = Instance.new("RemoteFunction")
				remote.Name = name
				remote.Parent = script

				local bindable_event = Instance.new("BindableEvent")
				bindable_event.Name = "ReturnDataFromGorpServer"
				bindable_event.Parent = remote

				local fire_actor = Instance.new("BindableEvent")
				fire_actor.Name = "InvokeGorpServer"
				fire_actor.Parent = remote
				return remote
			end)()
	else
		return script:WaitForChild(name) :: RemoteFunction
	end
end

return {}
