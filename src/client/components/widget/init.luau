local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local enabled = require(script.Parent.Parent.Parent.enabled)
local style = require(script.Parent.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)

local border = require(script.Parent.Parent.border)
local borders = require(script.borders)
local container = require(script.Parent.Parent.container)
local shadow = require(script.Parent.Parent.shadow)
local topbar = require(script.topbar)

local create = vide.create
local source = vide.source
local cleanup = vide.cleanup

type props = {

	title: (string | () -> string)?,
	min_size: Vector2?,
	position: Vector2?,
	size: Vector2?,

	children: (() -> Instance | { Instance })?,
	bind_to_close: (() -> ())?,

	[any]: any,
}

local highest_display_order = 100000
local RESIZE_RANGE = 4

return function(props: props)
	local min_size = props.min_size or Vector2.new(100, 100)
	local base_size = props.size or min_size * 1.5
	local title = props.title or ""
	local children = props.children
	local bind_to_close = props.bind_to_close
	local position = props.position or Vector2.zero

	local x_size = source(math.max(min_size.X, base_size.X))
	local y_size = source(math.max(min_size.Y, base_size.Y))
	local x_position = source(position.X or 100)
	local y_position = source(position.Y or 56)

	props.min_size = nil
	props.title = nil
	props.size = nil
	props.children = nil
	props.position = nil
	props.bind_to_close = nil

	local offset = source(Vector2.zero)
	local dragging = source(false)
	local absolute_position = source(Vector2.zero)
	local absolute_size = source(Vector2.zero)

	local can_resize_top = source(false)
	local can_resize_bottom = source(false)
	local can_resize_right = source(false)
	local can_resize_left = source(false)
	local resizing = source(false)
	local ref = source()
	local display_order = source(highest_display_order + 1)
	highest_display_order += 1

	local mouse_inside = source(false)

	local top: Vector2
	local bottom: Vector2

	cleanup(UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		resizing(false)
		dragging(false)
	end))

	cleanup(UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		if not resizing() then return end

		local mposition = UserInputService:GetMouseLocation()
		local top_inset, bottom_inset = GuiService:GetGuiInset()
		mposition -= top_inset + bottom_inset
		local x, y = mposition.X, mposition.Y

		if can_resize_bottom() then y_size(math.max(y - top.Y, min_size.Y)) end
		if can_resize_right() then x_size(math.max(x - top.X, min_size.X)) end
		if can_resize_top() then
			y_size(math.max(bottom.Y - y, min_size.Y))
			y_position(math.min(y, bottom.Y - min_size.Y))
		end
		if can_resize_left() then
			x_size(math.max(bottom.X - x, min_size.X))
			x_position(math.min(x, bottom.X - min_size.X))
		end
	end))

	cleanup(UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not dragging() then resizing(true) end

		top = absolute_position()
		bottom = absolute_position() + absolute_size()

		local player_gui
		if Players.LocalPlayer and RunService:IsRunning() then
			player_gui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
		elseif RunService:IsStudio() and RunService:IsRunning() then
			player_gui = game:GetService("CoreGui") :: any
		else
			return
		end

		local objects = player_gui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
		if #objects == 0 then return end
		if not objects[1]:IsDescendantOf(ref()) then return end

		display_order(highest_display_order + 1)
		highest_display_order += 1
	end))

	cleanup(UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging() == false then return end
		if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			dragging(false)
			return
		end

		local position = UserInputService:GetMouseLocation()
		x_position(position.X + offset().X)
		y_position(position.Y + offset().Y)
	end))

	return create "ScreenGui" {
		Parent = if RunService:IsStudio() and not RunService:IsRunning()
			then game:GetService("CoreGui")
			else Players.LocalPlayer:WaitForChild("PlayerGui"),

		Name = title,

		DisplayOrder = display_order,

		Enabled = enabled,

		vide.action(ref),

		shadow {

			Position = function()
				return UDim2.fromOffset(x_position(), y_position())
			end,
			Size = function()
				return UDim2.fromOffset(x_size() + 6, y_size() + 6)
			end,

			Active = true,

			create "Frame" {

				Size = UDim2.fromScale(1, 1),

				BackgroundColor3 = style.background,
				ZIndex = 100,

				topbar {
					title = title,
					dragging = dragging,
					offset = offset,
					bind_to_close = bind_to_close,
				},

				border {},

				borders {

					resize_range = RESIZE_RANGE,
					min_size = min_size,

					can_resize_top = can_resize_top,
					can_resize_bottom = can_resize_bottom,
					can_resize_left = can_resize_left,
					can_resize_right = can_resize_right,

					resizing = resizing,
				} :: vide.vFrame,

				container {
					Name = "Container",

					Size = function()
						return UDim2.new(1, 0, 1, -24)
					end,
					Position = UDim2.fromOffset(0, 24),

					children,
					props,
				},

				vide.changed("AbsolutePosition", absolute_position),
				vide.changed("AbsoluteSize", absolute_size),

				MouseMoved = function()
					if resizing() then return end

					local mposition = UserInputService:GetMouseLocation()
					local top_inset, bottom_inset = GuiService:GetGuiInset()
					mposition -= top_inset + bottom_inset
					local x, y = mposition.X, mposition.Y
					x -= absolute_position().X
					y -= absolute_position().Y

					can_resize_top(y < RESIZE_RANGE)
					can_resize_left(x < RESIZE_RANGE)
					can_resize_bottom(y > (absolute_size().Y - RESIZE_RANGE))
					can_resize_right(x > (absolute_size().X - RESIZE_RANGE))
				end,

				MouseEnter = function()
					mouse_inside(true)
				end,

				MouseLeave = function()
					if resizing() then return end
					if RunService:IsRunning() == false then return end

					mouse_inside(false)
				end,
			},
		},
	}
end
