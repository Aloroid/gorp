local background = require(script.Parent.Parent.Parent.components.background)
local button = require(script.Parent.Parent.Parent.components.button)
local container = require(script.Parent.Parent.Parent.components.container)
local convert_scale = require(script.Parent.Parent.Parent.Parent.modules.convert_scale)
local layout = require(script.Parent.Parent.Parent.components.layout)
local padding = require(script.Parent.Parent.Parent.components.padding)
local pane = require(script.Parent.Parent.Parent.components.pane)
local profiler = require(script.Parent.profiler)
local scrolling_frame = require(script.Parent.Parent.Parent.components.scrolling_frame)
local style = require(script.Parent.Parent.Parent.style)
local text = require(script.Parent.Parent.Parent.components.text)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)

local source = vide.source
local derive = vide.derive
local indexes = vide.indexes

type props = {

	system_name: string,
	system_times: () -> { number },
	system_labels: {
		{
			category: string,
			labels: () -> { string },
		}
	},

	destroy: () -> (),
}

local function scale(n: number)
	return convert_scale(n, "s")
end

return function(props: props)
	local system_times = props.system_times
	local system_labels = props.system_labels

	--- gets the average time based on the values
	local average = derive(function()
		local sum, total = 0, 0
		for _, value in system_times() do
			sum += value
			total += 1
		end
		return sum / total
	end)

	local function budget()
		local average = average()

		return average > 0.003 and 0.01
			or average > 0.001 and 0.005
			or average > 0.0009 and 0.002
			or average > 0.0004 and 0.001
			or average > 0.00015 and 0.0006
			or 0.00025
	end

	local function max()
		return math.max(unpack(system_times()))
	end

	local function min()
		return math.min(unpack(system_times()))
	end

	return background {

		layout {},

		pane {

			layout {},

			profiler {
				max = budget,
				values = system_times,
			},

			text {

				text = function()
					return `budget: {scale(budget())}\tmax: {scale(max())}\tmin: {scale(min())}\taverage: {scale(
						average()
					)}`
				end,

				layout = {
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
				},
			},
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

			indexes(source(system_labels), function(label, index)
				--print("created label for", label())

				local function labels()
					return label().labels()
				end

				return container {

					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,

					layout {},

					text {
						text = function()
							return label().category
						end,

						layout = {
							LayoutOrder = 0,
						},
					} :: any,

					indexes(labels, function(label, index)
						local function splitted()
							return string.split(label(), "\n")
						end

						return button {
							text = function()
								return splitted()[1]
							end,

							child = {
								padding { PaddingLeft = UDim.new(0, 2) } :: Instance,
							},

							layout = {
								Size = UDim2.new(1, 0, 0, 30),

								LayoutOrder = index,

								text {

									text = function()
										return splitted()[2] or ""
									end,
									text_size = 14,

									layout = {
										TextColor3 = style.sub_text,
										Position = UDim2.fromScale(1, 0.5),
										AnchorPoint = Vector2.new(1, 0.5),
									},
								} :: Instance,
							},
						}
					end),
				}
			end),
		},
	}
end
