local vide = require(script.Parent.Parent.Parent.vide)

local performance = require(script.Parent.system_view.performance)
local remotes = require(script.Parent.Parent.remotes)
local rolling_average = require(script.Parent.Parent.rolling_average)
local tabs = require(script.Parent.Parent.components.tabs)
local widget = require(script.Parent.Parent.components.widget)

local source = vide.source

return function(scheduler_index: number, index: number, name: string)
	return widget {

		title = name,
		min_size = Vector2.new(230, 200),
		closeable = true,

		tabs {
			{
				name = "Performance",
				child = function()
					local time = rolling_average.new()
					local views = source({})
					time.values = table.create(50, 0)

					local function get_query(encoded)
						return {
							s = encoded[1],
							t = encoded[2],
							ent = encoded[3],
							includes = encoded[4],
							excludes = encoded[5],
							is_group = encoded[6],
						}
					end

					task.spawn(function()
						local values, queries =
							remotes.get_system_performance_data:InvokeServer(
								scheduler_index,
								index
							)

						time.values = values

						for _, query in queries do
							table.insert(views(), get_query(query))
						end
						views(views())
					end)

					-- update code
					local connection = remotes.update_system_performance_data.OnClientEvent:Connect(
						function(scheduler_id, system_id, value, queries)
							if scheduler_id ~= scheduler_index then return end
							if system_id ~= index then return end

							time:add(value)
							local new = {}

							for _, query in queries do
								table.insert(new, get_query(query))
							end
							views(new)
						end
					)

					local ran_once = false
					return performance(time, views :: any, function()
						connection:Disconnect()
						-- next code must only run once else we're destroying 2 connections in strict
						if ran_once then return end
						ran_once = true
						remotes.stop_flow_system_performance_data:FireServer(
							scheduler_index,
							index
						)
					end)
				end,
			},
			--[[{
				name = "Watch",
				child = function()
					return text {
						text = "contains a panel that lets you preview the changes a system makes",

						layout = {
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							AutomaticSize = Enum.AutomaticSize.XY,
						},
					}
				end,
			},]]
		},
	}
end
