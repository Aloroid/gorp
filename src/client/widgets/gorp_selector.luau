--[[

	Allows for selecting a widget

]]
local RunService = game:GetService("RunService")

local button = require(script.Parent.Parent.components.button)
local cts = require(script.Parent.Parent.cts)
local gorp_registry = require(script.Parent.gorp_registry)
local layout = require(script.Parent.Parent.components.layout)
local padding = require(script.Parent.Parent.components.padding)
local pane = require(script.Parent.Parent.components.pane)
local registry = require(script.Parent.Parent.registry)
local scrolling_frame = require(script.Parent.Parent.components.scrolling_frame)
local vide = require(script.Parent.Parent.Parent.Parent.vide)
local widget = require(script.Parent.Parent.components.widget)

local create = vide.create
local source = vide.source
local indexes = vide.indexes
local cleanup = vide.cleanup

type Source<T> = vide.Source<T>

local SERVER = "rbxasset://textures/debugger/breakpoints/server.png"
local CLIENT = "rbxasset://textures/debugger/breakpoints/client.png"

local function entry(props: {
	value: () -> { name: string, from: "server" | "client" | string },
	key: number,
	visible: () -> boolean,
	activated: () -> (),
})
	local value, key, activated = props.value, props.key, props.activated

	return button {
		text = function() return value().name end,

		layout = {
			LayoutOrder = key,

			Visible = props.visible,
		},

		child = {
			layout {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
			} :: Instance,

			create "ImageLabel" {

				Size = UDim2.fromOffset(16, 16),

				BackgroundTransparency = 1,

				Image = function()
					return if value().from == "server" then SERVER elseif value().from == "client" then CLIENT else ""
				end,

				LayoutOrder = -1,
			},
		},

		activated = activated,
	}
end

return function()
	vide.root(function(destroy)
		local registries = source({})
		local schedulers = source({})
		local query = source("")

		local function update()
			local new_registries = {}
			local new_schedulers = {}

			for id, name, from in registry:view(cts.Name, cts.ReplicatedFrom, cts.Registry) do
				table.insert(new_registries, { name = name, id = id, from = from })
			end

			for id, name, from in registry:view(cts.Name, cts.ReplicatedFrom, cts.Scheduler) do
				table.insert(new_schedulers, { name = name, id = id, from = from })
			end

			registries(new_registries)
			schedulers(new_schedulers)
		end

		update()

		cleanup(RunService.Heartbeat:Connect(update))

		cleanup(widget {

			title = "Selector",

			min_size = Vector2.new(200, 200),

			--bind_to_close = destroy,

			scrolling_frame {

				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),

				padding {},

				layout {},

				pane {

					title = "Registries",

					layout {},

					indexes(registries, function(value, key)
						return entry {
							value = value,
							key = key,
							visible = function() return not not string.match(value().name, query()) end,
							activated = function()
								gorp_registry {
									registry_id = value().id,
								}
							end,
						}
					end),
				},

				pane {

					title = "Schedulers",

					layout {},

					indexes(schedulers, function(value, key)
						return entry {
							value = value,
							key = key,
							visible = function() return not not string.match(value().name, query()) end,
							activated = function() end,
						}
					end),
				},
			},
		})
	end)
end
