local TextService = game:GetService("TextService")

local style = require(script.Parent.Parent.style)
local vide = require(script.Parent.Parent.Parent.Parent.vide)

local border = require(script.Parent.border)
local corner = require(script.Parent.corner)
local padding = require(script.Parent.padding)

local create = vide.create
local source = vide.source
local effect = vide.effect
local untrack = vide.untrack

type text_input = {

	size: UDim2?,
	text: vide.Source<string>,
	text_size: number?,
	placeholder_text: (vide.Source<string> | string)?,

	multi_line: boolean?,
	automatic_size: Enum.AutomaticSize?,
	text_y_alignment: Enum.TextYAlignment?,

	disabled: vide.Source<boolean>?,

	focus_lost: ((text: string, enter_pressed: boolean) -> ())?,

	layout: { [any]: any }?,
}

local function text_input(props: text_input)
	local cursor_position = source(0)
	local clip_absolute_size = source(Vector2.zero)

	local text = props.text

	local text_offset = source(UDim2.new())
	local text_size = source(UDim2.new())
	local focused = source(false)
	local focus_lost = props.focus_lost or function() end :: never

	effect(function()
		local position = cursor_position()
		local text = text()

		local text_behind_cursor = string.sub(text, 1, position - 1)

		local font = style.font
		local font_size = 18
		local cursor_offset = TextService:GetTextSize(
			text_behind_cursor,
			font_size,
			font,
			Vector2.zero
		).X
		local text_width =
			TextService:GetTextSize(text, font_size, font, Vector2.zero).X

		local clip_absolute_size = clip_absolute_size() or Vector2.zero
		local textbox_offset = math.min(untrack(text_offset).X.Offset, 0)
		local textbox_width = clip_absolute_size.X - style.padding.Offset * 2
		local visible_start = -textbox_offset
		local visible_end = visible_start + textbox_width

		if cursor_offset <= visible_start then
			-- If the cursor is before the leading edge of the clip area, offset
			-- the TextBox so the cursor is at the leading edge.
			textbox_offset = -cursor_offset
		elseif cursor_offset >= visible_end then
			-- If the cursor is after the trailing edge of the clip area, offset
			-- the TextBox so the cursor is at the trailing edge.
			textbox_offset = -(cursor_offset - textbox_width)
		end

		local overflow = math.max(text_width - textbox_width, 0)
		textbox_offset = math.max(textbox_offset, -overflow)
		if cursor_offset == textbox_width - textbox_offset then
			textbox_offset -= 1
		end

		if focused() == true then
			text_offset(UDim2.new(0, textbox_offset, 0, 0))
		end
		text_size(UDim2.new(0, math.max(text_width, textbox_width), 1, 0))
	end)

	return create "Frame" {
		Name = "BaseTextInputClip",

		Size = props.size or UDim2.new(1, 0, 0, 32),

		ClipsDescendants = true,

		BackgroundColor3 = style.input,

		vide.changed("AbsoluteSize", clip_absolute_size),
		AutomaticSize = props.automatic_size or Enum.AutomaticSize.None,

		props.layout,

		create "TextBox" {

			Size = text_size,
			Position = text_offset,

			BackgroundTransparency = 1,

			TextEditable = props.disabled,

			MultiLine = props.multi_line or false,

			Text = text,
			Font = Enum.Font.Code,
			PlaceholderText = props.placeholder_text,

			TextColor3 = style.text,
			PlaceholderColor3 = style.sub_text,
			AutomaticSize = props.automatic_size or Enum.AutomaticSize.None,

			ClipsDescendants = true,

			TextSize = props.text_size or 16,

			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = props.text_y_alignment
				or Enum.TextYAlignment.Center,

			vide.changed("Text", text),
			vide.changed("CursorPosition", cursor_position),

			Focused = function() focused(true) end,

			FocusLost = function(enter)
				focused(false)
				focus_lost(text(), enter)
			end,
		},

		padding {},
		corner {},
		border {
			Color = function()
				if focused() then
					return style.border_selected
				else
					return style.border
				end
			end,
		},
	}
end

return text_input
