--[[

	Allows for selecting a widget

]]
local RunService = game:GetService("RunService")

local button = require(script.Parent.Parent.components.button)
local gorp_registry = require(script.Parent.gorp_registry)
local gorp_scheduler = require(script.Parent.gorp_scheduler)
local layout = require(script.Parent.Parent.components.layout)
local padding = require(script.Parent.Parent.components.padding)
local pane = require(script.Parent.Parent.components.pane)
local scrolling_frame = require(script.Parent.Parent.components.scrolling_frame)
local servers = require(script.Parent.Parent.servers)
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
		text = function()
			return value().name
		end,

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
	return vide.root(function(destroy)
		local registries = source({})
		local schedulers = source({})
		local query = source("")

		local function update()
			local new_registries = {}
			local new_schedulers = {}

			for namespace, servers in servers do
				for actor, server in servers do
					for id, registry in server.registries do
						table.insert(new_registries, { id = id, actor = actor, name = registry.name, from = namespace })
					end
					for id, scheduler in server.schedulers do
						table.insert(
							new_schedulers,
							{ id = id, actor = actor, name = scheduler.name, from = namespace }
						)
					end
				end
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
							visible = function()
								return not not string.match(value().name, query())
							end,
							activated = function()
								gorp_registry(value().from, value().actor, value().id)
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
							visible = function()
								return not not string.match(value().name, query())
							end,
							activated = function()
								gorp_scheduler(value().from, value().actor, value().id)
							end,
						}
					end),
				},
			},
		})
	end)
end
