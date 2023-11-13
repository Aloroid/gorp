local RunService = game:GetService("RunService")

local background = require(script.Parent.Parent.components.background)
local convert_scale = require(script.Parent.Parent.convert_scale)
local layout = require(script.Parent.Parent.components.layout)
local rts = require(script.Parent.Parent.rts)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)

local actions = require(script.Parent.Parent.actions)
local border = require(script.Parent.Parent.components.border)
local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local graph = require(script.graph)
local padding = require(script.Parent.Parent.components.padding)
local pane = require(script.Parent.Parent.components.pane)
local scrolling_frame = require(script.Parent.Parent.components.scrolling_frame)
local system_server_view = require(script.Parent.system_server_view)
local system_view = require(script.Parent.system_view)
local text = require(script.Parent.Parent.components.text)
local widget = require(script.Parent.Parent.components.widget)

local create = vide.create
local source = vide.source
local indexes = vide.indexes
local derive = vide.derive

local function get_color(n: number)
	return Color3.fromHSV((n - 1) * 0.15 % 1, 1, 1)
end

local RUNNING =
	"rbxasset://textures/StudioToolbox/AssetPreview/pause_button.png"
local PAUSED = "rbxasset://textures/StudioToolbox/AssetPreview/play_button.png"

return function(
	scheduler: rts.Scheduler,
	cleanup: (() -> ())?,
	server_scheduler_id: number?
)
	local heartbeat = source(0)
	local subtick = source(0)

	local runtime = function()
		heartbeat()

		local total = 0
		for i, value in scheduler.systems do
			if scheduler:get_paused(i) then continue end
			total += value.time:average()
		end
		return total
	end
	local graph_values = derive(function()
		heartbeat()

		local values = {}
		local is_completely_paused = #scheduler:get_all_paused()
			== #scheduler.systems

		for i, system in scheduler.systems do
			if scheduler:get_paused(i) and not is_completely_paused then
				continue
			end
			table.insert(
				values,
				{ color = get_color(i), value = system.time:average() }
			)
		end

		return values
	end)
	local systems = derive(function()
		heartbeat()
		return scheduler.systems
	end)

	-- updates the heartbeat, which controls certain ui
	local i = 0
	local connection = RunService.Heartbeat:Connect(function(dt)
		heartbeat(dt)
		i += 1
		if i % 10 == 0 then subtick(dt) end
	end)

	local selected = source(0)

	return widget {

		title = `Scheduler View: {scheduler.name}`,
		min_size = Vector2.new(300, 200),
		closeable = true,

		background {

			pane {

				container {

					Size = UDim2.new(1, 0, 0, 24),

					text {
						text = function()
							return `Run time: {convert_scale(runtime(), "s")}`
						end,
					},

					container {
						Position = UDim2.fromScale(1, 0),
						AnchorPoint = Vector2.new(1, 0),

						button {
							text = "Pause All",

							layout = {
								Size = UDim2.fromOffset(0, 24),
								AnchorPoint = Vector2.new(0, 1),
								AutomaticSize = Enum.AutomaticSize.XY,
							},

							activated = function()
								for i in scheduler.systems do
									scheduler:pause(i)
								end
							end,
						},

						button {
							text = "Resume All",

							layout = {
								Size = UDim2.fromOffset(0, 24),
								AnchorPoint = Vector2.new(0, 1),
								AutomaticSize = Enum.AutomaticSize.XY,
							},

							activated = function()
								for i in scheduler.systems do
									scheduler:resume(i)
								end
							end,
						},

						layout {
							HorizontalAlignment = Enum.HorizontalAlignment.Right,
							FillDirection = Enum.FillDirection.Horizontal,
						},
					},
				},

				graph {

					values = graph_values,
					selected = selected,
				},

				text {
					text = function()
						return `system: {if selected() == 0
							then ""
							else scheduler.systems[selected()].name}`
					end,

					font = Enum.Font.SourceSansBold,

					layout = {
						TextColor3 = function()
							return if selected() == 0
								then style.text
								else get_color(selected())
						end,
					},
				},

				text {
					text = function()
						heartbeat()
						return `{if selected() == 0
							then "0 ms"
							else convert_scale(
								scheduler.systems[selected()].time:average(),
								"s"
							)}`
					end,
				},

				layout {},
			},

			scrolling_frame {

				Size = UDim2.new(1, 0, 1, -136),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,

				indexes(systems, function(value, key)
					local pressed_paused = source(false)
					local hovering_paused = source(false)
					local paused = source(scheduler:get_paused(key))

					vide.cleanup(
						RunService.Heartbeat:Connect(
							function() paused(scheduler:get_paused(key)) end
						)
					)

					return button {
						text = function() return value().name end,
						color = function()
							return if paused()
								then style.sub_text
								else style.text
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

								BackgroundTransparency = vide.spring(
									function()
										return pressed_paused() and 0.7 or 1
									end,
									0.1,
									0.5
								),

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
									Transparency = vide.spring(
										function()
											return hovering_paused() and 0 or 1
										end,
										0.1
									),
								},

								Activated = function()
									if paused() then
										scheduler:resume(key)
									else
										scheduler:pause(key)
									end
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
									subtick()
									return convert_scale(
										scheduler.systems[key].time:average(),
										"s"
									)
								end,

								text_size = 14,
							},
						},

						activated = function()
							if server_scheduler_id then
								vide.mount(
									function()
										system_server_view(
											server_scheduler_id,
											key,
											value().name
										)
									end
								)
								return
							end
							vide.mount(
								function() system_view(scheduler, key) end
							)
						end,
					}
				end),

				padding {
					PaddingLeft = UDim.new(0, 2),
					PaddingRight = UDim.new(0, 12),
				},

				layout {},
			},

			layout {},
		},

		Destroying = function()
			connection:Disconnect()
			if cleanup then cleanup() end
		end,
	}
end
