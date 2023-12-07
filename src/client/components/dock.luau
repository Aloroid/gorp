local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local background = require(script.Parent.background)
local border = require(script.Parent.border)
local button = require(script.Parent.button)
local container = require(script.Parent.container)
local text = require(script.Parent.text)

local widgets = {}

local create = vide.create
local source = vide.source

type props = {

	widget_id: string?,
	title: (string | () -> string)?,
	min_size: number?,
	closeable: boolean?,

	[any]: any,
}

return function(props: props)
	local x_size = source((props.min_size or 75) * 1.5)
	local widget_id = props.widget_id or props.title or ""
	local min_size = props.min_size or 75
	local title = props.title or widget_id or ""
	local closesable = props.closeable

	local connection

	assert(widgets[props.widget_id] == nil, `{props.widget_id} already exists as a widget!`)

	props.closeable = nil
	props.widget_id = nil
	props.min_size = nil
	props.title = nil

	local hovering = source(false)
	local near_edge = source(false)
	local dragging = source(false)
	local absolute_position = source(Vector2.zero)
	local absolute_size = source(Vector2.zero)

	local normal

	return vide.root(function(destroy)
		local frame: Frame
		frame = create "Frame" {

			Size = function() return UDim2.new(0, x_size() + 12, 1, 0) end,

			BackgroundColor3 = style.background,
			ZIndex = 100,

			border {},

			create "Frame" {

				Size = UDim2.new(1, 0, 0, 24),

				BackgroundColor3 = style.foreground,

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

						activated = function()
							destroy()
							frame:Destroy()
						end,
					}
					else nil,

				border {},

				ZIndex = 1000,
			},

			container {

				Size = function() return UDim2.new(1, 0, 1, -24) end,
				Position = UDim2.fromOffset(0, 24),

				background {

					props,
				},
			},

			create "Frame" {

				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 12, 1, 0),
				AnchorPoint = Vector2.new(1, 0),

				BackgroundTransparency = 1,

				MouseEnter = function()
					hovering(true)
					normal = UserInputService.MouseIcon
					UserInputService.MouseIcon = "rbxasset://textures/StudioUIEditor/icon_resize2.png"
				end,

				MouseLeave = function()
					hovering(false)
					UserInputService.MouseIcon = normal
				end,

				InputBegan = function(input: InputObject)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
					local x = input.Position.X

					dragging(true)
					local begin_x = x
					local begin_size = x_size()

					connection = RunService.Heartbeat:Connect(function(delta_time)
						local location = UserInputService:GetMouseLocation()
						local new = location.X

						if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) == false then
							dragging(false)
							connection:Disconnect()
							return
						end

						x_size(math.max(min_size, begin_size + new - begin_x))
					end)
				end,
			},

			vide.changed("AbsolutePosition", absolute_position),
			vide.changed("AbsoluteSize", absolute_size),

			MouseMoved = function(x: number, y: number)
				local ending_x = absolute_position().X + absolute_size().X

				near_edge(ending_x - x < 24)
			end,

			MouseLeave = function() near_edge(false) end,
		}
		return frame
	end)
end
