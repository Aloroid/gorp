local state = require(script.Parent.Parent.state)
local vide = require(script.Parent.Parent.Parent.vide)

local entity_client_view = require(script.Parent.entity_client_view)

local button = require(script.Parent.Parent.components.button)
local entity_server_view = require(script.Parent.entity_server_view)
local layout = require(script.Parent.Parent.components.layout)
local padding = require(script.Parent.Parent.components.padding)
local pane = require(script.Parent.Parent.components.pane)
local remotes = require(script.Parent.Parent.remotes)
local scheduler_view = require(script.Parent.scheduler_view)
local scrolling_frame = require(script.Parent.Parent.components.scrolling_frame)
local widget = require(script.Parent.Parent.components.widget)

local create = vide.create
local source = vide.source
local values = vide.values
local cleanup = vide.cleanup

local function entry(props: {
	value: { name: string },
	key: () -> number,
	image: string,
	activated: () -> (),
})
	local value, key, image, activated =
		props.value, props.key, props.image, props.activated

	return button {
		text = value.name,

		layout = {
			LayoutOrder = key,
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

				Image = image,

				LayoutOrder = -1,
			},
		},

		activated = activated,
	}
end

return function()
	local to_cleanup = {}

	return widget {

		title = "Registry Selector",
		min_size = Vector2.new(150, 100),
		closeable = false,

		scrolling_frame {

			AutomaticCanvasSize = Enum.AutomaticSize.Y,

			padding {},

			layout {
				Padding = UDim.new(0, 16),
			},

			pane {
				title = "worlds",

				layout {},

				values(state.worlds, function(value, key)
					return entry {
						value = value,
						key = key,
						image = "rbxasset://textures/debugger/breakpoints/client.png",
						activated = function()
							state.current_client_world(value)
							table.insert(
								to_cleanup,
								vide.mount(entity_client_view)
							)
						end,
					}
				end),

				values(
					source(remotes.get_server_registries:InvokeServer()),
					function(value, key)
						return entry {
							value = { name = value },
							key = key,
							image = "rbxasset://textures/debugger/breakpoints/server.png",
							activated = function()
								table.insert(
									to_cleanup,
									vide.mount(
										function()
											return entity_server_view(
												value,
												key()
											)
										end
									)
								)
							end,
						}
					end
				),
			},

			pane {
				title = "schedulers",

				layout {},

				values(state.schedulers, function(value, key)
					return entry {
						value = value,
						key = key,
						image = "rbxasset://textures/debugger/breakpoints/client.png",
						activated = function()
							table.insert(
								to_cleanup,
								vide.mount(
									function() return scheduler_view(value) end
								)
							)
						end,
					}
				end),
			},

			cleanup(function()
				for _, callback in to_cleanup do
					callback()
				end
			end),
		},
	}
end
