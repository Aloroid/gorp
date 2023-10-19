local RunService = game:GetService("RunService")

local background = require(script.Parent.Parent.components.background)
local convert_scale = require(script.Parent.Parent.convert_scale)
local layout = require(script.Parent.Parent.components.layout)
local rts = require(script.Parent.Parent.rts)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)

local button = require(script.Parent.Parent.components.button)
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
		for _, value in scheduler.systems do
			total += value.time:average()
		end
		return total
	end
	local graph_values = derive(function()
		heartbeat()

		local values = {}

		for i, system in scheduler.systems do
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

				text {
					text = function()
						return `Run time: {convert_scale(runtime(), "s")}`
					end,
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
					return button {
						text = function() return value().name end,

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

							text {

								layout = {

									AutomaticSize = Enum.AutomaticSize.X,
									Position = UDim2.fromScale(1, 0.5),
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
