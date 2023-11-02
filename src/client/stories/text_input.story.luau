local vide = require(script.Parent.Parent.Parent.Parent.vide)

local background = require(script.Parent.Parent.components.background)
local border = require(script.Parent.Parent.components.border)
local corner = require(script.Parent.Parent.components.corner)
local layout = require(script.Parent.Parent.components.layout)
local padding = require(script.Parent.Parent.components.padding)
local style = require(script.Parent.Parent.style)
local text = require(script.Parent.Parent.components.text)
local text_input = require(script.Parent.Parent.components.text_input)

local create = vide.create

return function(target: ScreenGui)
	local destroy = vide.mount(
		function()
			return background {

				text {
					text = "custom",
				},

				text_input {
					text = vide.source(
						"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sagittis vitae ante in cursus. Morbi quis accumsan ligula, eu malesuada diam. Mauris porta auctor ipsum. Curabitur molestie, sapien at lobortis fermentum, augue sapien ullamcorper tortor, nec vehicula ipsum nunc at erat. Donec vel purus semper, aliquam mi sed, aliquet dui. Aenean pretium nisl sem, in interdum dui lobortis eu. Vestibulum a velit dolor. Integer porttitor libero ac massa faucibus, id finibus tortor dapibus. Aliquam rhoncus id tellus ut efficitur. Sed sit amet convallis purus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Interdum et malesuada fames ac ante ipsum primis in faucibus. Nunc euismod a metus sit amet tristique. Donec euismod dignissim libero, ut suscipit dui ullamcorper ac. "
					),
				},

				text {
					text = "standard textbox",
				},

				create "Frame" {
					Name = "BaseTextInputClip",

					Size = UDim2.new(1, 0, 0, 32),

					ClipsDescendants = true,

					BackgroundColor3 = style.button_pressed,

					create "TextBox" {

						Size = UDim2.fromScale(1, 1),
						AutomaticSize = Enum.AutomaticSize.X,

						BackgroundTransparency = 1,

						Text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sagittis vitae ante in cursus. Morbi quis accumsan ligula, eu malesuada diam. Mauris porta auctor ipsum. Curabitur molestie, sapien at lobortis fermentum, augue sapien ullamcorper tortor, nec vehicula ipsum nunc at erat. Donec vel purus semper, aliquam mi sed, aliquet dui. Aenean pretium nisl sem, in interdum dui lobortis eu. Vestibulum a velit dolor. Integer porttitor libero ac massa faucibus, id finibus tortor dapibus. Aliquam rhoncus id tellus ut efficitur. Sed sit amet convallis purus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Interdum et malesuada fames ac ante ipsum primis in faucibus. Nunc euismod a metus sit amet tristique. Donec euismod dignissim libero, ut suscipit dui ullamcorper ac. ",

						TextColor3 = style.text,
						PlaceholderColor3 = style.text,

						ClipsDescendants = true,

						TextSize = 18,

						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					},

					padding {},
					corner {},
					border {},
				},

				layout {},
			}
		end,
		target
	)

	return function() destroy() end
end
