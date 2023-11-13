local state = require(script.Parent.Parent.state)
local vide = require(script.Parent.Parent.Parent.vide)

local button = require(script.Parent.Parent.components.button)
local layout = require(script.Parent.Parent.components.layout)
local padding = require(script.Parent.Parent.components.padding)
local pane = require(script.Parent.Parent.components.pane)
local remotes = require(script.Parent.Parent.remotes)
local scrolling_frame = require(script.Parent.Parent.components.scrolling_frame)
local style = require(script.Parent.Parent.style)
local text = require(script.Parent.Parent.components.text)
local text_input = require(script.Parent.Parent.components.text_input)
local widget = require(script.Parent.Parent.components.widget)

local entity_client_view = require(script.Parent.entity_client_view)
local entity_server_view = require(script.Parent.entity_server_view)
local scheduler_server_view = require(script.Parent.scheduler_server_view)
local scheduler_view = require(script.Parent.scheduler_view)

local create = vide.create
local source = vide.source
local values = vide.values
local cleanup = vide.cleanup

local SERVER = "rbxasset://textures/debugger/breakpoints/server.png"
local CLIENT = "rbxasset://textures/debugger/breakpoints/client.png"

local function entry(props: {
	value: { name: string },
	key: () -> number,
	image: string,
	visible: () -> boolean,
	activated: () -> (),
})
	local value, key, image, activated =
		props.value, props.key, props.image, props.activated

	return button {
		text = value.name,

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

				Image = image,

				LayoutOrder = -1,
			},
		},

		activated = activated,
	}
end

local function registry_selector()
	local query = source("")
	local total_entries = source(0)
	local stored_widgets = {}

	local server_registries =
		source(remotes.get_server_registries:InvokeServer())
	local server_schedulers =
		source(remotes.get_server_schedulers:InvokeServer())
	local server_average_time = source(1 / 60)

	cleanup(remotes.share_server_fps.OnClientEvent:Connect(server_average_time))

	cleanup(
		remotes.updated_server_registries.OnClientEvent:Connect(
			server_registries
		)
	)

	cleanup(
		remotes.updated_server_schedulers.OnClientEvent:Connect(
			server_schedulers
		)
	)

	return widget {

		title = "View Selector",
		min_size = Vector2.new(150, 150),
		closeable = false,

		scrolling_frame {

			AutomaticCanvasSize = Enum.AutomaticSize.Y,

			padding {},

			layout {
				Padding = UDim.new(0, 16),
			},

			text_input {
				text = query,
				placeholder_text = "Search",

				size = UDim2.new(1, 0, 0, 28),
				text_size = 14,

				layout = {

					Visible = function()
						return total_entries()
								+ #state.custom_widgets()
								+ #state.worlds()
								+ #state.schedulers()
							> 5
					end,
				},
			},

			pane {
				title = "worlds",

				layout {},

				values(state.worlds, function(value, key)
					return entry {
						value = value,
						key = key,
						image = CLIENT,
						visible = function()
							return not not string.match(
								string.lower(value.name),
								string.lower(query())
							)
						end,
						activated = function()
							if stored_widgets[`client_reg:{value}`] then
								local ok =
									pcall(stored_widgets[`client_reg:{value}`])
								if ok then return end
							end

							state.current_client_world(value)
							stored_widgets[`client_reg:{value}`] =
								vide.mount(entity_client_view)
						end,
					}
				end),

				values(server_registries, function(value, key)
					total_entries(total_entries() + 1)
					return entry {
						value = { name = value },
						key = key,
						image = SERVER,
						visible = function()
							return not not string.match(
								string.lower(value),
								string.lower(query())
							)
						end,
						activated = function()
							if stored_widgets[`server_reg:{value}`] then
								local ok =
									pcall(stored_widgets[`server_reg:{value}`])
								if ok then return end
							end

							stored_widgets[`server_reg:{value}`] = vide.mount(
								function()
									return entity_server_view(value, key())
								end
							)
						end,
					}
				end),
			},

			pane {
				title = "schedulers",

				layout {},

				values(state.schedulers, function(value, key)
					return entry {
						value = value,
						key = key,
						image = CLIENT,
						visible = function()
							return not not string.match(
								string.lower(value.name),
								string.lower(query())
							)
						end,
						activated = function()
							if stored_widgets[`client_sch:{value}`] then
								local ok =
									pcall(stored_widgets[`client_sch:{value}`])
								if ok then return end
							end

							stored_widgets[`client_sch:{value}`] = vide.mount(
								function() return scheduler_view(value) end
							)
						end,
					}
				end),

				values(server_schedulers, function(value, key)
					total_entries(total_entries() + 1)
					return entry {
						value = { name = value },
						key = key,
						image = SERVER,
						visible = function()
							return not not string.match(
								string.lower(value),
								string.lower(query())
							)
						end,
						activated = function()
							if stored_widgets[`server_sch:{value}`] then
								local ok =
									pcall(stored_widgets[`server_sch:{value}`])
								if ok then return end
							end

							stored_widgets[`server_sch:{value}`] = vide.mount(
								function()
									return scheduler_server_view(value, key())
								end
							)
						end,
					}
				end),
			},

			pane {
				title = "custom",

				layout {},

				values(state.custom_widgets, function(value, key)
					return entry {
						value = value,
						key = key,
						image = if value.type == "client"
							then CLIENT
							elseif value.type == "server" then SERVER
							else "",
						visible = function()
							return not not string.match(
								string.lower(value.name),
								string.lower(query())
							)
						end,
						activated = function() vide.mount(value.callback) end,
					}
				end),

				Visible = function() return #state.custom_widgets() > 0 end,
			},

			button {
				text = "Close All Widgets",

				activated = function()
					for _, destroy in state.widgets do
						pcall(destroy)
					end
					table.clear(state.widgets)

					vide.mount(registry_selector)
				end,
			},

			text {
				text = function()
					return string.format(
						"Server FPS: %.1f, %.1f ms",
						1 / server_average_time(),
						server_average_time() * 1000
					)
				end,

				layout = {
					TextColor3 = style.sub_text,
				},
			},
		},
	}
end

return registry_selector
