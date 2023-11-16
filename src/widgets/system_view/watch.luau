--!optimize 2
--!native
-- watches ar

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local border = require(script.Parent.Parent.Parent.components.border)
local button = require(script.Parent.Parent.Parent.components.button)
local ecr = require(script.Parent.Parent.Parent.Parent.ecr)
local state = require(script.Parent.Parent.Parent.state)
local style = require(script.Parent.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local container = require(script.Parent.Parent.Parent.components.container)
local horizontal_scroller =
	require(script.Parent.Parent.Parent.components.horizontal_scroller)
local layout = require(script.Parent.Parent.Parent.components.layout)
local rbxjson = require(script.Parent.Parent.Parent.rbxjson)
local rts = require(script.Parent.Parent.Parent.rts)
local table_ui = require(script.Parent.Parent.Parent.components.table)
local text = require(script.Parent.Parent.Parent.components.text)
local text_input = require(script.Parent.Parent.Parent.components.text_input)

local create = vide.create
local derive = vide.derive
local source = vide.source
local cleanup = vide.cleanup

local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.new(0, 1, 0)

return function(
	changes: vide.Source<{ number }>,
	frame: vide.Source<number>,
	logs: vide.Source<{ any }>,
	recording: vide.Source<boolean>,
	disable: () -> ()
)
	local heartbeat = source(0)
	local used_frames = derive(function()
		local changed = changes()
		local changed_frames = {}

		for frame, changes in changed do
			if changes == 0 then continue end
			table.insert(changed_frames, frame)
		end

		return changed_frames
	end)
	local max_changes = derive(
		function() return math.max(0, unpack(changes())) end
	)

	-- this is all here to make sure the profiler doesn't move
	local canvas_position = source(Vector2.new(4 * #changes(), 0))
	local absolute_size = source(Vector2.zero)
	local hovering_frame = source() :: rts.Source<number?>
	local prev = 0
	vide.effect(function()
		local current = vide.untrack(canvas_position)
		local diff = #changes() * 6 - prev * 6
		prev = #changes()

		canvas_position(Vector2.new(current.X + diff, 0))
	end)

	cleanup(RunService.Heartbeat:Connect(heartbeat))

	return container {

		layout {},

		-- profiler for showing changes
		horizontal_scroller {

			layout = {
				Size = UDim2.new(1, 0, 0, 48),

				BackgroundColor3 = style.foreground,
				BackgroundTransparency = 0,

				CanvasPosition = canvas_position,

				vide.changed("CanvasPosition", canvas_position),
				vide.changed("AbsoluteSize", absolute_size),
			},

			max_items = function() return #changes() end,
			item_size = 6,

			child = function(index)
				local key = function() return index() end
				local amount = function() return changes()[key()] or 0 end

				return container {

					BackgroundColor3 = WHITE,
					BackgroundTransparency = function()
						return if hovering_frame() == key() then 0.5 else 1
					end,

					MouseEnter = function() hovering_frame(key()) end,

					MouseLeave = function()
						if hovering_frame() == key() then
							hovering_frame(nil)
						end
					end,

					ZIndex = 100,

					InputBegan = function(input)
						if
							input.UserInputType
							== Enum.UserInputType.MouseButton1
						then
							frame(table.find(used_frames(), key()) or 0)
						end
					end,

					container {
						Size = function()
							return UDim2.fromScale(1, amount() / max_changes())
						end,

						BackgroundColor3 = function()
							return if used_frames()[frame()] == key()
								then GREEN
								else WHITE
						end,

						BackgroundTransparency = function()
							return if hovering_frame() == key() then 0.5 else 0
						end,

						Position = UDim2.fromScale(0, 1),
						AnchorPoint = Vector2.new(0, 1),

						create "UIGradient" {

							Color = ColorSequence.new(
								style.microprofiler_bar_top,
								style.microprofiler_bar_bot
							),
							Rotation = 90,
						},
					},
				}
			end,

			border {},
		},

		-- tooltip
		create "ScreenGui" {

			DisplayOrder = 1e8,

			Name = "hover",
			IgnoreGuiInset = true,

			container {

				Size = UDim2.new(),
				AutomaticSize = Enum.AutomaticSize.XY,

				Position = function()
					heartbeat()
					local location = UserInputService:GetMouseLocation()
					return UDim2.fromOffset(location.X + 16, location.Y + 16)
				end,

				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,

				Visible = function() return hovering_frame() ~= nil end,

				text {
					text = function()
						return `Frame: {hovering_frame()}\nChanged Frame: {table.find(
							used_frames(),
							hovering_frame() or -1
						)}\nChanges: {changes()[hovering_frame() or 1]}`
					end,

					layout = {
						TextXAlignment = Enum.TextXAlignment.Left,
					},
				},
			},
		},

		-- setting frame

		container {

			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,

			layout {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},

			button {
				layout = {
					Size = UDim2.fromOffset(54, 26),
					AutomaticSize = Enum.AutomaticSize.XY,
				},

				child = {
					layout {
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					},
				},

				text = function()
					return if recording() then "Finish" else "Record"
				end,

				activated = function() recording(not recording()) end,
			},

			text {
				text = function()
					return `Recorded {#used_frames()}/{#changes()}`
				end,
			},

			text_input {

				size = UDim2.fromOffset(40, 26),

				text = source("0"),
				text_size = 14,
				placeholder_text = "0",

				focus_lost = function(text, enter)
					if not enter then return end
					local n = tonumber(text)
					if not n then return end
					if not (n > 0 and n <= #used_frames()) then return end
					if n ~= math.floor(n) then return end

					frame(table.find(used_frames(), n) or 0)
				end,
			},
		},

		-- logs

		table_ui {

			meaning = source({
				"type",
				--"world",
				"entity",
				"component",
				"value",
			}),
			max_rows = function() return #logs() end,

			layout = {
				Size = UDim2.new(1, 0, 1, -106),
			},

			item_size = 24,

			display = function(_, column, row)
				local value = function()
					local values = logs()[row()]
					return if values then values[column] else -1
				end

				return text {

					layout = {
						Size = UDim2.fromScale(1, 1),
					},

					text = function()
						local value = value()
						-- type
						if column == 1 then
							return if value == 1
								then "added"
								elseif value == 2 then "changed"
								elseif value == 3 then "removing"
								else ""
						-- entity
						elseif column == 2 then
							local key, ver = ecr.extract(value)
							return `{key}:{ver}`
						elseif column == 3 then
							local ctypes = state.cts.ids()
							return ctypes[value] or "unknown"
						elseif column == 4 then
							return if type(value) == "table"
								then rbxjson:Encode(value)
								else tostring(value)
						else
							return ""
						end
					end,
				}
			end,
		},

		Destroying = function() disable() end,
	}
end
