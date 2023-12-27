local actions = require(script.Parent.Parent.actions)
local border = require(script.Parent.Parent.components.border)
local button = require(script.Parent.Parent.components.button)
local convert_scale = require(script.Parent.Parent.Parent.modules.convert_scale)
local layout = require(script.Parent.Parent.components.layout)
local remotes = require(script.Parent.Parent.Parent.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local servers = require(script.Parent.Parent.servers)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local graph = require(script.graph)
local padding = require(script.Parent.Parent.components.padding)
local pane = require(script.Parent.Parent.components.pane)
local scrolling_frame = require(script.Parent.Parent.components.scrolling_frame)
local style = require(script.Parent.Parent.style)
local text = require(script.Parent.Parent.components.text)
local widget = require(script.Parent.Parent.components.widget)

local create = vide.create
local source = vide.source
local indexes = vide.indexes
local cleanup = vide.cleanup

local function get_color(n: number)
	return Color3.fromHSV((n - 1) * 0.15 % 1, 1, 1)
end

local RUNNING = "rbxasset://textures/StudioToolbox/AssetPreview/pause_button.png"
local PAUSED = "rbxasset://textures/StudioToolbox/AssetPreview/play_button.png"

type Source<T> = vide.Source<T>
type SchedulerData = {

	average_times: buffer,
	paused: buffer,
	system_order_changes: {
		[number]: { name: string, old: number, new: number } | { old: number, new: nil },
	},
}

--- Reads a bool from a buffer based on an index. This uses indexes starting from 1
local function get_bool_from_buffer(bools: buffer, index: number): boolean
	return bit32.btest(
		buffer.readu8(bools, (index - 1) // 8), -- reads the byte from the buffer
		bit32.lshift(1, (index - 1) % 8) -- calculates the position to extract the bit from
	) -- this will automatically coerce the bool into either a true/false value
end

local function generate_ui(namespace: "client" | "server", actor_id: number, scheduler_id: number, destroy)
	local server = servers[namespace][actor_id]
	local scheduler = server.schedulers[scheduler_id]

	local connector = {
		namespace = namespace,
		to = actor_id,
	}

	local scheduler_systems: Source<{ { name: string, time: Source<number>, paused: Source<boolean> } }> = source {}
	local selected = source(0)
	local subscription_id = -1

	task.spawn(function()
		subscription_id = remotes.subscribe_scheduler:invoke(connector, scheduler_id)
		print("received subscription id", subscription_id)
	end)

	-- handles replication of the scheduler and updating the internal data structure
	cleanup(remotes.replicate_scheduler:connect(function(connector, incoming_id: number, packet: SchedulerData)
		--if subscription_id == -1 then task.wait() end -- delay a little so it can arrive
		connector = reverse_connector(connector)

		--print("received packet", connector.to, actor_id, connector.namespace, namespace, incoming_id, subscription_id)
		if connector.to ~= actor_id then return end
		if connector.namespace ~= namespace then return end
		if incoming_id ~= subscription_id then return end

		local new_pending_scheduler_systems = table.clone(scheduler_systems())

		-- First we have to update the order of the scheduler
		for _, new_data in packet.system_order_changes do
			-- We write this to a new table based on the old one.
			new_pending_scheduler_systems[new_data.old or -1] = nil
			if new_data.new == nil then continue end

			local old_system_data = scheduler_systems()[new_data.old or -1]
				or {
					name = new_data.name,
					time = source(0),
					paused = source(false),
				}

			new_pending_scheduler_systems[new_data.new] = old_system_data
		end

		-- After we've updated the scheduler, we update the paused listings
		for i, system in new_pending_scheduler_systems do
			system.paused(get_bool_from_buffer(packet.paused, i))
		end

		-- And then we update the average times.
		for i, system in new_pending_scheduler_systems do
			if system.paused() then continue end
			local t = buffer.readf32(packet.average_times, (i - 1) * 4)
			system.time(t)
		end

		if #packet.system_order_changes == 0 then return end
		scheduler_systems(new_pending_scheduler_systems)
	end))

	cleanup(function()
		remotes.unsubscribe_scheduler:fire(connector, subscription_id)
	end)

	local function is_completely_paused()
		for _, system in scheduler_systems() do
			if not system.paused() then return false end
		end
		return true
	end

	cleanup(widget {

		title = `Scheduler: {scheduler.name}`,

		min_size = Vector2.new(200, 200),
		size = Vector2.new(300, 450),

		bind_to_close = destroy,

		padding {},

		layout {},

		pane {

			layout {},

			graph {

				values = indexes(scheduler_systems, function(entry, index)
					return {
						value = function()
							return entry().time()
						end,
						color = get_color(index),
						visible = function()
							return not entry().paused() or is_completely_paused()
						end,
					}
				end),

				selected = selected,
			},

			text {
				text = function()
					local system_data = scheduler_systems()[selected()]
					return `System: {system_data and system_data.name or ""}`
				end,
				color = function()
					return selected() == 0 and Color3.fromHSV(0, 0, 0.8) or get_color(selected())
				end,
				font = Enum.Font.SourceSansBold,
			},

			text {
				text = function()
					local system_data = scheduler_systems()[selected()]
					return `Averaged Run Time: {system_data and convert_scale(system_data.time(), "s") or "0.00 ms"}`
				end,
			},
		},

		scrolling_frame {

			Size = UDim2.new(1, 0, 1, -136),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,

			layout {},

			padding {
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 12),
			},

			indexes(scheduler_systems, function(value, key)
				local pressed_paused = source(false)
				local hovering_paused = source(false)

				local function paused()
					return value().paused()
				end

				return button {
					text = function()
						return value().name
					end,
					color = function()
						return if paused() then style.sub_text else style.text
					end,

					child = {

						create "Frame" {

							Size = UDim2.fromOffset(16, 16),

							BackgroundColor3 = function()
								return get_color(key)
							end,

							LayoutOrder = -1,

							create "UICorner" {
								CornerRadius = UDim.new(1, 0),
							},
						} :: any,

						layout {
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
						},
					},

					layout = {
						Size = UDim2.new(1, 0, 0, 30) :: any,

						create "ImageButton" {

							Position = UDim2.fromScale(1, 0.5),
							Size = UDim2.fromOffset(26, 26),
							AnchorPoint = Vector2.new(1, 0.5),

							BackgroundColor3 = Color3.new(),

							BackgroundTransparency = vide.spring(function()
								return pressed_paused() and 0.7 or 1
							end, 0.1, 0.5),

							Image = function()
								return paused() and PAUSED or RUNNING
							end,

							ImageColor3 = style.text,

							LayoutOrder = -1,

							actions.pressed(pressed_paused),
							actions.hovering(hovering_paused),

							create "UICorner" {
								CornerRadius = style.corner_radius,
							},

							border {
								Transparency = vide.spring(function()
									return hovering_paused() and 0 or 1
								end, 0.1),
							},

							Activated = function()
								remotes.pause_system:fire(connector, scheduler_id, value().name, not paused())
							end,
						} :: any,

						text {

							layout = {

								AutomaticSize = Enum.AutomaticSize.X,
								Position = UDim2.new(1, -32, 0.5, 0),
								AnchorPoint = Vector2.new(1, 0.5),

								TextColor3 = style.sub_text,
							},

							text = function()
								return convert_scale(value().time(), "s")
							end,

							text_size = 14,
						},
					},

					activated = function() end,
				}
			end),
		},
	})
end

return function(namespace: "client" | "server", actor_id: number, scheduler_id: number)
	vide.root(function(destroy)
		generate_ui(namespace, actor_id, scheduler_id, destroy)
	end)
end
