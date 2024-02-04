local background = require(script.Parent.Parent.components.background)
local button = require(script.Parent.Parent.components.button)
local layout = require(script.Parent.Parent.components.layout)
local padding = require(script.Parent.Parent.components.padding)
local scrolling_frame = require(script.Parent.Parent.components.scrolling_frame)
local text_input = require(script.Parent.Parent.components.text_input)
local vide = require(script.Parent.Parent.Parent.Parent.vide)
local widget = require(script.Parent.Parent.components.widget)

local source = vide.source
local cleanup = vide.cleanup
local untrack = vide.untrack

type props = {

	title: string?,

	text: vide.Source<string>,
	disabled: (boolean | () -> boolean)?,

	on_save: ((input: string) -> ())?,
	on_close: ((input: string) -> ())?,

	destroy: () -> (),
}

local function text_editor(props: props)
	local text = props.text
	local result = source(untrack(text))
	local on_close = props.on_close
	local on_save = props.on_save

	cleanup(function()
		if not on_close then return end
		on_close(text())
	end)

	cleanup(widget {

		title = `Editor: {props.title}`,
		min_size = Vector2.new(250, 200),
		size = Vector2.new(300, 300),
		bind_to_close = props.destroy,

		background {

			layout {},

			scrolling_frame {

				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, -32),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,

				padding {
					PaddingLeft = UDim.new(0, 2),
					PaddingRight = UDim.new(0, 2),
					PaddingTop = UDim.new(0, 2),
					PaddingBottom = UDim.new(0, 2),
				},

				text_input {

					layout = {
						Size = UDim2.new(1, -4, 1, 0),
					},

					text = text,
					automatic_size = Enum.AutomaticSize.Y,
					text_y_alignment = Enum.TextYAlignment.Top,
					disabled = props.disabled,
					multi_line = true,

					focus_lost = function()
						result(text())
					end,
				},
			},

			button {

				text = "Apply changes",

				activated = function()
					if not on_save then return end
					on_save(result())
				end,

				disabled = props.disabled,
			},
		},
	})
end

type text_editor = {

	title: string?,

	text: vide.Source<string>,
	disabled: (boolean | () -> boolean)?,

	on_save: ((input: string) -> ())?,
	on_close: ((input: string) -> ())?,
}

return function(props: text_editor)
	return vide.root(function(destroy)
		text_editor {

			title = props.title,
			text = props.text,
			disabled = props.disabled,

			on_save = props.on_save,
			on_close = props.on_close,

			destroy = destroy,
		}
	end)
end
