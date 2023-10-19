--!optimize 2
--!native
local RunService = game:GetService("RunService")

local border = require(script.Parent.Parent.Parent.components.border)
local button = require(script.Parent.Parent.Parent.components.button)
local rts = require(script.Parent.Parent.Parent.rts)
local style = require(script.Parent.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local container = require(script.Parent.Parent.Parent.components.container)
local convert_scale = require(script.Parent.Parent.Parent.convert_scale)
local layout = require(script.Parent.Parent.Parent.components.layout)
local padding = require(script.Parent.Parent.Parent.components.padding)
local pane = require(script.Parent.Parent.Parent.components.pane)
local rolling_average = require(script.Parent.Parent.Parent.rolling_average)
local scrolling_frame =
	require(script.Parent.Parent.Parent.components.scrolling_frame)
local state = require(script.Parent.Parent.Parent.state)
local system_query_hook = require(script.Parent.Parent.Parent.system_query_hook)
local text = require(script.Parent.Parent.Parent.components.text)

local create = vide.create
local derive = vide.derive
local source = vide.source
local indexes = vide.indexes
local cleanup = vide.cleanup

local RED = Color3.new(1, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.new(0, 1, 0)

local ENABLE_LINES = false

local function transform(n: number) return convert_scale(n, "s") end

return function(scheduler: rts.Scheduler, index: number)
	local system = scheduler.systems[index]
	local values = system.time.values

	local heartbeat = source(0)
	local budget = derive(function()
		heartbeat()
		local average = system.time:average()

		return average > 0.004 and 0.010
			or average > 0.001 and 0.004
			or average > 0.0006 and 0.001
			or 0.0006
	end)
	local max = derive(function()
		heartbeat()
		return math.max(unpack(system.time.values))
	end)
	local min = derive(function()
		heartbeat()
		return math.min(unpack(system.time.values))
	end)

	cleanup(RunService.Heartbeat:Connect(heartbeat))

	-- track queries.
	-- we inject a call into every single world and modify their :view call so
	-- that we can trace it.
	local hook = system_query_hook.new(scheduler, index)
	local disable = hook:enable()
	local views = hook.views

	return container {

		layout {},

		pane {

			layout {},

			container {

				Size = UDim2.new(1, 0, 0, 48),

				BackgroundColor3 = style.foreground,
				BackgroundTransparency = 0,
				ClipsDescendants = true,

				indexes(function()
					heartbeat()
					return values
				end, function(value, key)
					return container {

						Size = function()
							return UDim2.fromScale(
								1 / #values,
								value() / budget()
							)
						end,
						Position = function()
							return UDim2.fromScale(1 / #values * (key - 1), 1)
						end,
						AnchorPoint = Vector2.new(0, 1),

						BackgroundColor3 = function()
							return if value() > budget() then RED else WHITE
						end,
						BackgroundTransparency = 0,

						create "UIGradient" {

							Color = ColorSequence.new(
								style.microprofiler_bar_top,
								style.microprofiler_bar_bot
							),
							Rotation = 90,
						},
					}
				end),

				if ENABLE_LINES
					then { -- average line
						container {

							Size = UDim2.new(1, 0, 0, 1),
							Position = function()
								heartbeat()
								return UDim2.fromScale(
									0,
									1 - (system.time:average() / budget())
								)
							end,

							BackgroundColor3 = WHITE,
							BackgroundTransparency = 0,
						},

						-- max
						container {

							Size = UDim2.new(1, 0, 0, 1),
							Position = function()
								heartbeat()
								return UDim2.fromScale(
									0,
									1 - (max() / budget())
								)
							end,

							BackgroundColor3 = RED,
							BackgroundTransparency = 0,
						},
						-- min
						container {

							Size = UDim2.new(1, 0, 0, 1),
							Position = function()
								heartbeat()
								return UDim2.fromScale(
									0,
									1 - (min() / budget())
								)
							end,

							BackgroundColor3 = GREEN,
							BackgroundTransparency = 0,
						},
					}
					else nil,

				border {},
			},

			text {
				text = function()
					heartbeat()
					return `budget: {transform(budget())}\tmax: {transform(min())}\tmin: {transform(max())}\taverage: {transform(
						system.time:average()
					)}`
				end,

				layout = {
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
				},
			},
		},

		text {
			text = "Query Health",
		},

		scrolling_frame {

			Size = UDim2.new(1, 0, 1, -138),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,

			layout {},
			padding {
				PaddingTop = UDim.new(0, 2),
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 2),
			},

			indexes(views, function(value, index)
				local average_s = rolling_average.new(50)
				local average_t = rolling_average.new(50)

				return button {

					text = function()
						local view = value()

						local includes = {}
						local excludes = {}

						for _, ctype in view.includes do
							local name = state.cts.ids()[ctype] or `#{ctype}`
							table.insert(includes, `{name}`)
						end

						for _, ctype in (view.excludes or {} :: never) do
							local name = state.cts.ids()[ctype] or `#{ctype}`
							table.insert(excludes, `!{name}`)
						end

						return `{table.concat(includes, ", ")}{if #excludes > 0 then ", " else ""}{table.concat(excludes, ", ")}`
					end,

					child = {
						padding { PaddingLeft = UDim.new(0, 2) },
					},

					layout = {
						Size = UDim2.new(1, 0, 0, 30),

						text {

							text = function()
								local view = value()
								average_s:add(view.s / view.ent)
								average_t:add(view.t)

								return `{transform(average_t:average())}, {transform(average_s:average())}/ent, {view.ent} ent, {if view.is_group
									then "group"
									else ""}`
							end,
							text_size = 14,

							layout = {
								TextColor3 = style.sub_text,
								Position = UDim2.fromScale(1, 0.5),
								AnchorPoint = Vector2.new(1, 0.5),
							},
						},
					},
				}
			end),
		},

		Destroying = function() disable() end,
	}
end
