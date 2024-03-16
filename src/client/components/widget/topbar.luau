local actions = require(script.Parent.Parent.Parent.Parent.actions)
local style = require(script.Parent.Parent.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.Parent.vide)

local border = require(script.Parent.Parent.Parent.border)
local text = require(script.Parent.Parent.Parent.text)

local create = vide.create
local source = vide.source
local changed = vide.changed

type Source<T> = vide.Source<T>
type props = {

	title: (string | () -> string)?,
	bind_to_close: (() -> ())?,

	dragging: Source<boolean>,
	offset: (new: Vector2) -> (),

	[any]: any,
}

return function(props: props)
	local title = props.title or ""
	local bind_to_close = props.bind_to_close
	local dragging = props.dragging
	local offset = props.offset

	local closeable = not not bind_to_close

	local absolute_position = source(Vector2.zero)

	local hover_closed = source(false)
	local pressed_closed = source(false)

	return create "TextButton" {
		Name = "Topbar",

		Size = UDim2.new(1, 0, 0, 24),

		BackgroundColor3 = style.foreground,

		Text = "",

		changed("AbsolutePosition", absolute_position),

		text {
			layout = {
				Size = UDim2.fromScale(1, 1),
				AnchorPoint = Vector2.zero,
				Position = UDim2.new(),
			},
			text = title or "test",
		},

		if closeable ~= false
			then create "TextButton" {
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 44, 1, 0),
				AnchorPoint = Vector2.new(1, 0.5),

				BackgroundColor3 = vide.spring(function()
					return if pressed_closed() and hover_closed()
						then style.close_button_pressed
						elseif hover_closed() then style.close_button
						else style.foreground
				end, 0.1),

				create "ImageLabel" {

					Size = UDim2.fromOffset(12, 12),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),

					BackgroundTransparency = 1,

					Image = "rbxasset://textures/ui/InspectMenu/x.png",
				},

				Text = "",

				actions.hovering(hover_closed),
				actions.pressed(pressed_closed),
				Activated = bind_to_close,
			}
			else nil,

		border {},

		MouseButton1Down = function(x, y)
			offset(absolute_position() - Vector2.new(x, y))
			dragging(true)
		end,

		ZIndex = 1000,
	}
end
