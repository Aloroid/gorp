local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local rbxjson = require(script.Parent.Parent.rbxjson)
local style = require(ReplicatedStorage.Packages.gorp.style)
local vide = require(script.Parent.Parent.Parent.vide)

local background = require(script.Parent.Parent.components.background)
local button = require(script.Parent.Parent.components.button)
local layout = require(script.Parent.Parent.components.layout)
local scrolling_frame = require(script.Parent.Parent.components.scrolling_frame)
local text_input = require(script.Parent.Parent.components.text_input)
local widget = require(script.Parent.Parent.components.widget)

local source = vide.source
local create = vide.create

type props = {
	name: string,
	text: string,
	updated: (text: string) -> (),
	prettify: boolean?,
	--world: { world: rts.Registry, name: string },
}

return function(props: props)
	local result = source(props.text)
	local value = if props.prettify
		then source(rbxjson:Prettify(props.text))
		else source(props.text)

	local size = TextService:GetTextSize(
		(value :: any)(),
		16,
		Enum.Font.Code,
		Vector2.one * math.huge
	) * 1.1

	return widget {
		title = "JSON: " .. props.name or "?",
		min_size = Vector2.new(150, 150),
		size = size + Vector2.new(32, 64),
		closeable = true,

		background {
			Size = UDim2.fromScale(1, 1),

			layout {} :: any,

			scrolling_frame {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, -32),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,

				create "UIPadding" {
					PaddingLeft = UDim.new(0, 2),
					PaddingRight = UDim.new(0, 12),
					PaddingTop = UDim.new(0, 2),
					PaddingBottom = UDim.new(0, 2),
				},

				text_input {
					layout = {
						Size = UDim2.fromScale(1, 1),
					},

					text = value,
					automatic_size = Enum.AutomaticSize.Y,
					text_y_alignment = Enum.TextYAlignment.Top,
					multi_line = true,

					focus_lost = function(text) result(text) end, --unparsed_query(raw_text()) end,
				},
			},

			button {
				activated = function() props.updated(result()) end,
				text = "Update",
			},
		},
	}
end
