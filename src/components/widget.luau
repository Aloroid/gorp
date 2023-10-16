local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local actions = require(script.Parent.Parent.actions)
local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.vide)

local background = require(script.Parent.background)
local border = require(script.Parent.border)
local button = require(script.Parent.button)
local container = require(script.Parent.container)
local shadow = require(script.Parent.shadow)
local text = require(script.Parent.text)

local widgets = {}

local create = vide.create
local source = vide.source
local cleanup = vide.cleanup

type props = {

	widget_id: string?,
	title: (string | () -> string)?,
	min_size: Vector2?,
	closeable: boolean?,

	[any]: any,
}

local highest_display_order = 100000
local RESIZE_RANGE = 8

return function(props: props)
	local widget_id = props.widget_id or props.title or ""
	local min_size = props.min_size or Vector2.new(100, 100)
	local title = props.title or widget_id or ""
	local closesable = props.closeable

	local x_size = source(min_size.X * 1.5)
	local y_size = source(min_size.Y * 1.5)
	local x_position = source(100)
	local y_position = source(56)

	assert(
		widgets[props.widget_id] == nil,
		`{props.widget_id} already exists as a widget!`
	)

	props.closeable = nil
	props.widget_id = nil
	props.min_size = nil
	props.title = nil

	local offset = Vector2.zero
	local dragging = source(false)
	local absolute_position = source(Vector2.zero)
	local absolute_size = source(Vector2.zero)

	local can_resize_top = false
	local can_resize_bottom = false
	local can_resize_right = false
	local can_resize_left = false
	local resizing = source(false)
	local ref = source()
	local display_order = source(highest_display_order + 1)
	highest_display_order += 1

	local top
	local bottom
	local normal

	return vide.root(function(destroy)
		local gui = create "ScreenGui" {
			Parent = if RunService:IsStudio()
					and not RunService:IsRunning()
				then game:GetService("CoreGui")
				else Players.LocalPlayer:WaitForChild("PlayerGui"),

			Name = widget_id,

			DisplayOrder = display_order,

			vide.action(ref),

			shadow {

				Position = function()
					return UDim2.fromOffset(x_position(), y_position())
				end,

				Size = function()
					return UDim2.fromOffset(x_size() + 6, y_size() + 6)
				end,

				create "Frame" {

					Size = UDim2.fromScale(1, 1),

					BackgroundColor3 = style.background,
					ZIndex = 100,

					border {},

					-- Topbar
					create "TextButton" {
						Name = "Topbar",

						Size = UDim2.new(1, 0, 0, 24),

						BackgroundColor3 = style.foreground,

						Text = "",

						text {
							layout = {
								Size = UDim2.fromScale(1, 1),
								AnchorPoint = Vector2.zero,
								Position = UDim2.new(),
							},
							text = title or "test",
						},

						if closesable ~= false
							then button {
								layout = {
									Position = UDim2.new(1, -4, 0.5, 0),
									Size = UDim2.fromOffset(16, 16),
									AnchorPoint = Vector2.new(1, 0.5),
								},

								text = "x",

								activated = function() destroy() end,
							}
							else nil,

						border {},

						MouseButton1Down = function(x, y)
							offset = absolute_position() - Vector2.new(x, y)
							dragging(true)
						end,

						actions.cleanup(
							RunService.RenderStepped:Connect(function()
								if dragging() == false then return end
								if
									not UserInputService:IsMouseButtonPressed(
										Enum.UserInputType.MouseButton1
									)
								then
									dragging(false)
									return
								end

								local position =
									UserInputService:GetMouseLocation()
								x_position(position.X + offset.X)
								y_position(position.Y + offset.Y)
							end)
						),

						ZIndex = 1000,
					},

					container {
						Name = "Container",

						Size = function() return UDim2.new(1, 0, 1, -24) end,
						Position = UDim2.fromOffset(0, 24),

						background {

							props,
						},
					},

					actions.output("AbsolutePosition", absolute_position),
					actions.output("AbsoluteSize", absolute_size),

					MouseMoved = function()
						if resizing() then return end

						local mposition = UserInputService:GetMouseLocation()
						local top_inset, bottom_inset = GuiService:GetGuiInset()
						mposition -= top_inset + bottom_inset
						local x, y = mposition.X, mposition.Y
						x -= absolute_position().X
						y -= absolute_position().Y

						can_resize_top = y < RESIZE_RANGE
						can_resize_left = x < RESIZE_RANGE
						can_resize_bottom = y
							> (absolute_size().Y - RESIZE_RANGE)
						can_resize_right = x
							> (absolute_size().X - RESIZE_RANGE)

						if RunService:IsRunning() == false then return end
						if normal then UserInputService.MouseIcon = normal end
						normal = UserInputService.MouseIcon

						if
							(can_resize_top and can_resize_left)
							or (can_resize_bottom and can_resize_right)
						then
							UserInputService.MouseIcon =
								"rbxasset://textures/StudioUIEditor/icon_resize3.png"
						elseif
							(can_resize_top and can_resize_right)
							or (can_resize_bottom and can_resize_left)
						then
							UserInputService.MouseIcon =
								"rbxasset://textures/StudioUIEditor/icon_resize1.png"
						elseif can_resize_top or can_resize_bottom then
							UserInputService.MouseIcon =
								"rbxasset://textures/StudioUIEditor/icon_resize4.png"
						elseif can_resize_left or can_resize_right then
							UserInputService.MouseIcon =
								"rbxasset://textures/StudioUIEditor/icon_resize2.png"
						end
					end,

					MouseLeave = function()
						if resizing() then return end
						if RunService:IsRunning() == false then return end
						if normal then UserInputService.MouseIcon = normal end
					end,

					InputBegan = function(input: InputObject)
						if
							input.UserInputType
							~= Enum.UserInputType.MouseButton1
						then
							return
						end

						resizing(true)
						top = absolute_position()
						bottom = absolute_position() + absolute_size()
					end,

					cleanup(RunService.RenderStepped:Connect(function()
						local mposition = UserInputService:GetMouseLocation()
						local top_inset, bottom_inset = GuiService:GetGuiInset()
						mposition -= top_inset + bottom_inset
						local x, y = mposition.X, mposition.Y

						resizing(
							resizing()
								and (
									UserInputService:IsMouseButtonPressed(
										Enum.UserInputType.MouseButton1
									)
								)
						)

						if not resizing() then return end

						if can_resize_bottom then
							y_size(math.max(y - top.Y, min_size.Y))
						end
						if can_resize_right then
							x_size(math.max(x - top.X, min_size.X))
						end
						if can_resize_top then
							y_size(math.max(bottom.Y - y, min_size.Y))
							y_position(math.min(y, bottom.Y - min_size.Y))
						end
						if can_resize_left then
							x_size(math.max(bottom.X - x, min_size.X))
							x_position(math.min(x, bottom.X - min_size.X))
						end
					end)),

					cleanup(UserInputService.InputBegan:Connect(function(input)
						local player_gui = Players.LocalPlayer:WaitForChild(
							"PlayerGui"
						) :: PlayerGui
						local objects = player_gui:GetGuiObjectsAtPosition(
							input.Position.X,
							input.Position.Y
						)
						if #objects == 0 then return end
						if not objects[1]:IsDescendantOf(ref()) then return end

						display_order(highest_display_order + 1)
						highest_display_order += 1
					end)),
				},
			},
		}

		cleanup(gui)

		return gui
	end)
end
