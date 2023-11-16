local vide = require(script.Parent.Parent.Parent.vide)

local performance = require(script.Parent.system_view.performance)
local remotes = require(script.Parent.Parent.remotes)
local rolling_average = require(script.Parent.Parent.rolling_average)
local tabs = require(script.Parent.Parent.components.tabs)
local watch = require(script.Parent.system_view.watch)
local widget = require(script.Parent.Parent.components.widget)

local source = vide.source
local effect = vide.effect

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
			{
				name = "Watch",
				child = function()
					local changes = source({})
					local frame = source(0)
					local logs = source({})
					local recording = source(false)
					local id = -1

					task.spawn(
						function()
							id =
								remotes.register_system_watch_data:InvokeServer(
									scheduler_index,
									index
								)
						end
					)

					local connection = remotes.update_system_watch_data.OnClientEvent:Connect(
						function(s, i, t)
							if s ~= scheduler_index then return end
							if i ~= id then return end

							table.insert(changes(), t)
							changes(changes())
						end
					)

					local function cleanup()
						connection:Disconnect()

						while id < 0 do
							task.wait()
						end

						remotes.clear_system_watch_data:FireServer(
							scheduler_index,
							id
						)
					end

					effect(function()
						recording()
						if id <= 0 then return end

						if recording() then
							remotes.start_system_watch_data:FireServer(
								scheduler_index,
								id
							)
							changes({})
						else
							remotes.stop_system_watch_data:FireServer(
								scheduler_index,
								id
							)
						end
					end)

					effect(function()
						recording()
						if id <= 0 then return end

						if recording() then
							logs({})
						else
							local frame = frame()

							logs({})

							task.spawn(function()
								local data =
									remotes.get_system_watch_logs:InvokeServer(
										scheduler_index,
										id,
										frame
									)
								if recording() then return end
								if data == nil then return end

								logs(data)
							end)
						end
					end)

					return watch(changes, frame, logs, recording, cleanup)
				end,
			},
		},
	}
end
